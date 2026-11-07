import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/time/clock_format.dart';
import '../../../health/application/app_info_provider.dart';
import '../../../health/application/current_app_package_provider.dart';
import '../../../health/application/health_connect_gateway_provider.dart';
import '../../../health/domain/sleep_data_source.dart';
import '../../../health/domain/sleepy3_health_source.dart';
import '../../../sleep_tracking/application/sleep_session_edit_service.dart';
import '../../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../../../sleep_tracking/domain/session_edit.dart';
import '../../../sleep_tracking/domain/sleep_duration.dart';
import '../../../sleep_tracking/domain/sleep_goal.dart';
import '../../../sleep_tracking/domain/sleep_session.dart';
import 'sleep_goal_mark.dart';

/// Opens the session editor for one closed session.
///
/// Editable sessions keep the adaptive editor with Save. Read-only sessions
/// open a details view with locked fields, a read-only reason card and a single
/// dismiss action; the full-screen variant only has its close affordance.
Future<SleepSessionEditResult?> showSessionEditor(
  BuildContext context, {
  required SleepSession session,
  required SleepDataSource source,
  required SessionEditAccess access,
}) async {
  if (access == SessionEditAccess.readOnly) {
    return _showReadOnlySession(context, session: session, source: source);
  }

  final dialogController = M3EDialogController();
  final editorKey = GlobalKey<SessionEditorState>();

  try {
    return await M3EDialog.showAdaptive<SleepSessionEditResult>(
      context,
      title: 'Session',
      content: SessionEditor(
        key: editorKey,
        session: session,
        source: source,
        access: access,
        dialogController: dialogController,
      ),
      confirmLabel: 'Save',
      onConfirm: () =>
          unawaited(editorKey.currentState?.save() ?? Future<void>.value()),
      controller: dialogController,
    );
  } finally {
    // The route future completes after the dialog is gone, so the controller
    // can be released without waiting for another frame.
    dialogController.dispose();
  }
}

/// The read-only variant: details on compact windows, a basic dialog on wider
/// ones, and no Save or Delete action.
Future<SleepSessionEditResult?> _showReadOnlySession(
  BuildContext context, {
  required SleepSession session,
  required SleepDataSource source,
}) {
  final content = SessionEditor(
    session: session,
    source: source,
    access: SessionEditAccess.readOnly,
  );
  final theme = M3ETheme.of(context);
  final isCompact =
      MediaQuery.sizeOf(context).width < theme.dialogTheme.compactBreakpoint;

  if (isCompact) {
    return M3EDialog.showFullScreen<SleepSessionEditResult>(
      context,
      title: 'Session',
      body: SingleChildScrollView(child: content),
    );
  }

  return M3EDialog.show<SleepSessionEditResult>(
    context,
    dialog: M3EDialog(
      title: 'Session',
      content: content,
      actions: [
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// The form shown by [showSessionEditor].
///
/// It owns the draft times, validates them against the current history and
/// sends the result through the tracking controller. Closing after a successful
/// save or delete returns a [SleepSessionEditResult] to Stats.
class SessionEditor extends ConsumerStatefulWidget {
  SessionEditor({
    super.key,
    required this.session,
    required this.source,
    required this.access,
    this.dialogController,
  }) : assert(session.endedAt != null, 'The editor needs a closed session');

  final SleepSession session;
  final SleepDataSource source;

  /// Whether the session can be changed in the selected source.
  final SessionEditAccess access;

  /// Keeps the discard confirmation in sync with the draft.
  final M3EDialogController? dialogController;

  @override
  ConsumerState<SessionEditor> createState() => SessionEditorState();
}

class SessionEditorState extends ConsumerState<SessionEditor> {
  late DateTime _startedAt;
  late DateTime _endedAt;
  List<SessionEditError> _errors = const [];
  bool _saving = false;
  bool _deleting = false;

  bool get _canEdit => widget.access == SessionEditAccess.editAndDelete;

  bool get _isDirty =>
      _startedAt != widget.session.startedAt ||
      _endedAt != widget.session.endedAt;

  bool get _showsHealthNotice =>
      _canEdit &&
      (widget.source == SleepDataSource.healthConnect ||
          widget.session.healthRecordId != null);

  @override
  void initState() {
    super.initState();
    _startedAt = widget.session.startedAt;
    _endedAt = widget.session.endedAt!;
  }

  /// Validates and saves the draft. Called by the adaptive dialog's Save action.
  Future<void> save() async {
    if (!_canEdit || _saving || _deleting) return;

    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    setState(() {
      _saving = true;
      _errors = const [];
    });

    final result = await ref
        .read(sleepTrackingControllerProvider.notifier)
        .updateClosedSession(
          session: widget.session,
          startedAt: _startedAt,
          endedAt: _endedAt,
        );
    if (!mounted) return;

    setState(() => _saving = false);

    if (result.status == SleepSessionEditStatus.saved ||
        result.status == SleepSessionEditStatus.savedPendingSync) {
      _close(result);
      return;
    }

    if (result.status == SleepSessionEditStatus.permissionNeeded) {
      if (result.hasLocalChange) {
        // The local copy is already saved; Stats explains the pending sync.
        _close(result);
      } else {
        await _showError(
          title: 'Google Health needs permission',
          message:
              'Allow Sleepy3 to write sleep data in Google Health, then try '
              'again.',
        );
      }
      return;
    }

    final error = result.error;
    if (error is SessionEditError) {
      setState(() => _errors = [error]);
      return;
    }

    await _showError(
      title: "Couldn't save",
      message: 'The session could not be saved. Try again.',
    );
  }

  List<SessionEditError> _validate() {
    final state = ref.read(sleepTrackingControllerProvider);
    return validateSessionEdit(
      draft: SessionEditDraft(
        startedAt: _startedAt,
        endedAt: _endedAt,
        originalStartedAt: widget.session.startedAt,
        originalEndedAt: widget.session.endedAt,
      ),
      now: ref.read(sleepClockProvider)(),
      otherClosedSessions: state.closedSessions.where(
        (session) => !session.hasSameIdentityAs(widget.session),
      ),
      openSession: state.openSession,
    );
  }

  Future<void> _pickStartDate() async {
    if (!_canEdit) return;
    final picked = await M3EDatePicker.show(
      context,
      initialDate: _startedAt,
      firstDate: DateTime(1970),
      lastDate: _lastPickableDate,
      currentDate: ref.read(sleepClockProvider)(),
      helpText: 'Select sleep date',
    );
    if (picked == null || !mounted) return;

    _setDraft(_withDate(_startedAt, picked), _endedAt);
  }

  Future<void> _pickEndDate() async {
    if (!_canEdit) return;
    final picked = await M3EDatePicker.show(
      context,
      initialDate: _endedAt,
      firstDate: DateTime(1970),
      lastDate: _lastPickableDate,
      currentDate: ref.read(sleepClockProvider)(),
      helpText: 'Select wake date',
    );
    if (picked == null || !mounted) return;

    _setDraft(_startedAt, _withDate(_endedAt, picked));
  }

  Future<void> _pickStartTime() async {
    if (!_canEdit) return;
    final picked = await M3ETimePicker.show(
      context,
      initialTime: M3ETime(hour: _startedAt.hour, minute: _startedAt.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      helpText: 'Select sleep time',
    );
    if (picked == null || !mounted) return;

    _setDraft(_withTime(_startedAt, picked), _endedAt);
  }

  Future<void> _pickEndTime() async {
    if (!_canEdit) return;
    final picked = await M3ETimePicker.show(
      context,
      initialTime: M3ETime(hour: _endedAt.hour, minute: _endedAt.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      helpText: 'Select wake time',
    );
    if (picked == null || !mounted) return;

    _setDraft(_startedAt, _withTime(_endedAt, picked));
  }

  void _setDraft(DateTime startedAt, DateTime endedAt) {
    setState(() {
      _startedAt = startedAt;
      _endedAt = endedAt;
      _errors = const [];
    });
    widget.dialogController?.hasUnsavedChanges = _isDirty;
  }

  DateTime get _lastPickableDate {
    final now = ref.read(sleepClockProvider)();
    final today = _dateOnly(now);
    final start = _dateOnly(_startedAt);
    final end = _dateOnly(_endedAt);
    final latest = start.isAfter(end) ? start : end;
    return latest.isAfter(today) ? latest : today;
  }

  Future<void> _confirmDelete() async {
    if (!_canEdit || _saving || _deleting) return;

    final confirmed = await M3EDialog.show<bool>(
      context,
      dialog: M3EDialog(
        title: 'Delete session?',
        content: Text(_deleteMessage),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _deleting = true);
    var result = await _delete();
    if (!mounted) return;

    if (result.status == SleepSessionEditStatus.permissionNeeded) {
      setState(() => _deleting = false);
      final allow = await _askToAllowDelete();
      if (!mounted || allow != true) return;

      final granted = await _requestWriteAccess();
      if (!mounted) return;
      if (!granted) {
        await _showError(
          title: 'Google Health needs permission',
          message:
              'Allow Sleepy3 to write sleep data in Google Health, then try '
              'again.',
        );
        return;
      }

      setState(() => _deleting = true);
      result = await _delete();
      if (!mounted) return;
    }

    setState(() => _deleting = false);

    if (result.isDeleted) {
      _close(result);
      return;
    }

    await _showError(
      title: result.status == SleepSessionEditStatus.permissionNeeded
          ? 'Google Health needs permission'
          : "Couldn't delete",
      message: result.status == SleepSessionEditStatus.permissionNeeded
          ? 'Allow Sleepy3 to delete this session from Google Health, then '
                'try again.'
          : 'The session could not be deleted. Try again.',
    );
  }

  Future<SleepSessionEditResult> _delete() {
    return ref
        .read(sleepTrackingControllerProvider.notifier)
        .deleteClosedSession(widget.session);
  }

  Future<bool?> _askToAllowDelete() {
    return M3EDialog.show<bool>(
      context,
      dialog: M3EDialog(
        title: 'Google Health needs permission',
        content: const Text(
          'Allow Sleepy3 to delete this session from Google Health.',
        ),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestWriteAccess() async {
    try {
      return await ref
          .read(healthConnectGatewayProvider)
          .requestPermissions(read: true, write: true);
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not request Health Connect write access: '
        '$error\n$stackTrace',
      );
      return false;
    }
  }

  String get _deleteMessage {
    if (widget.source == SleepDataSource.healthConnect) {
      return 'This night will be deleted from Google Health. Its local copy '
          'is removed too when there is one.';
    }
    if (widget.session.healthRecordId != null) {
      return 'This night will be deleted from Sleepy3 and Google Health.';
    }
    return 'This night will be deleted from Sleepy3.';
  }

  void _close(SleepSessionEditResult result) {
    final controller = widget.dialogController;
    if (controller != null && controller.isOpen) {
      controller.hasUnsavedChanges = false;
      controller.close(result);
      return;
    }
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<void> _showError({required String title, required String message}) {
    return M3EDialog.show<void>(
      context,
      dialog: M3EDialog(
        title: title,
        content: Text(message),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;
    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);
    final duration = _endedAt.difference(_startedAt);
    final canEdit = _canEdit;
    final now = ref.read(sleepClockProvider)();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SessionHero(
          duration: duration,
          endedAt: _endedAt,
          spokenDate: _spokenDate.format(_endedAt),
        ),
        if (!canEdit) ...[
          const SizedBox(height: 24),
          _ReadOnlyCard(message: _readOnlyMessage()),
        ],
        const SizedBox(height: 24),
        _SessionSection(
          title: 'Fell asleep',
          enabled: canEdit,
          date: _formatEditorDateRow(_startedAt, now),
          time: formatSessionTime(_startedAt, use24HourFormat: use24HourFormat),
          onPickDate: _pickStartDate,
          onPickTime: _pickStartTime,
        ),
        const SizedBox(height: 24),
        _SessionSection(
          title: 'Woke up',
          enabled: canEdit,
          date: _formatEditorDateRow(_endedAt, now),
          time: formatSessionTime(_endedAt, use24HourFormat: use24HourFormat),
          onPickDate: _pickEndDate,
          onPickTime: _pickEndTime,
        ),
        if (canEdit && _showsHealthNotice) ...[
          const SizedBox(height: 16),
          _HealthNotice(
            message: widget.source == SleepDataSource.healthConnect
                ? 'This night is stored in Google Health. Saving updates the '
                      'Health Connect record.'
                : 'This night is also in Google Health. Saving updates both '
                      'copies.',
          ),
        ],
        if (canEdit && _errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final error in _errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                error.message,
                style: theme.typography.baseline.bodySmall.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
        ],
        if (canEdit) ...[
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: M3EButton(
              style: M3EButtonStyle.text,
              enabled: !_saving && !_deleting,
              onPressed: _confirmDelete,
              decoration: M3EButtonDecoration(
                foregroundColor: WidgetStatePropertyAll<Color?>(scheme.error),
              ),
              child: const Text('Delete session'),
            ),
          ),
        ],
      ],
    );
  }

  /// Why the session is read-only, using the source app when Android can
  /// resolve its label.
  String _readOnlyMessage() {
    final session = widget.session;
    final currentPackage = ref.read(currentAppPackageProvider);
    final otherBuild = isOtherSleepy3Build(session.sourceId, currentPackage);

    if (widget.source == SleepDataSource.healthConnect) {
      if (otherBuild) {
        return 'This session was created in ${_otherBuildName()}, so it '
            "can't be edited from this build.";
      }
      if (isSleepy3HealthRecord(session.sourceId)) {
        return "This session can't be edited from Sleepy3.";
      }
      return 'This session was created in ${_sourceAppLabel()}, so it '
          "can't be edited from Sleepy3.";
    }

    if (widget.source == SleepDataSource.local && session.isDownloaded) {
      if (otherBuild) {
        return 'This session was created in ${_otherBuildName()}. Downloaded '
            "copies can't be edited from this build.";
      }
      if (isSleepy3HealthRecord(session.sourceId)) {
        return 'This session was downloaded from Google Health. Switch to '
            'Google Health to edit it.';
      }
      if (session.sourceId != null) {
        return 'This session was created in ${_sourceAppLabel()}. Downloaded '
            "copies can't be edited in Local.";
      }
      return "This session was downloaded from Google Health. Downloaded "
          "copies can't be edited in Local.";
    }

    return "This session can't be edited from Sleepy3.";
  }

  String _otherBuildName() {
    final label = _sourceAppLabel();
    return label == 'another app' ? 'another Sleepy3 build' : label;
  }

  String _sourceAppLabel() {
    final sourceId = widget.session.sourceId;
    if (sourceId == null) return 'another app';
    final label = ref.watch(appLabelProvider(sourceId)).asData?.value;
    return label ?? 'another app';
  }
}

/// The session's identity: duration, goal comparison and wake day.
///
/// From M3: a filled card with `primaryContainer` / `onPrimaryContainer` and
/// `headlineMedium` (28/36) for the duration. The accent container makes the
/// night the leading element; secondary information uses neutral surfaces.
///
/// My design decisions (not in M3): the 56 dp goal mark, the 20 dp card radius
/// shared with the history cards, the 16 dp padding and gap, and the wording
/// of the goal line.
class _SessionHero extends StatelessWidget {
  const _SessionHero({
    required this.duration,
    required this.endedAt,
    required this.spokenDate,
  });

  final Duration duration;
  final DateTime endedAt;
  final String spokenDate;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      label:
          '${formatSpokenSleepDuration(duration)}, ${_spokenGoal(duration)}, '
          'woke $spokenDate',
      child: ExcludeSemantics(
        child: M3ECard(
          variant: M3ECardVariant.filled,
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SleepGoalMark(
                    duration: duration,
                    size: 56,
                    strokeWidth: 5,
                    color: scheme.primary,
                    onColor: scheme.onPrimary,
                    trackColor: scheme.onPrimaryContainer.withValues(
                      alpha: 0.18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      formatSleepDuration(duration),
                      style: theme.typography.emphasized.headlineMedium
                          .copyWith(
                            color: scheme.onPrimaryContainer,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _goalLabel(duration),
                style: theme.typography.baseline.bodyMedium.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Woke ${_formatEditorDate(endedAt)}',
                style: theme.typography.baseline.bodySmall.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The goal line under the duration, for example `Goal met · 13m over the
/// 8h goal` or `58m short of the 8h goal`.
String _goalLabel(Duration duration) {
  if (duration <= Duration.zero) return 'Your 8h goal';

  final difference = duration - dailySleepGoal;
  if (difference >= Duration.zero) {
    if (difference == Duration.zero) return 'Goal met';
    return 'Goal met · ${_goalDelta(difference)} over the 8h goal';
  }
  return '${_goalDelta(-difference)} short of the 8h goal';
}

/// The same comparison for screen readers.
String _spokenGoal(Duration duration) {
  if (duration <= Duration.zero) return '8-hour goal';

  final difference = duration - dailySleepGoal;
  if (difference == Duration.zero) return 'goal met';
  if (difference > Duration.zero) {
    return 'goal met, ${formatSpokenSleepDuration(difference)} over the '
        '8-hour goal';
  }
  return '${formatSpokenSleepDuration(-difference)} short of the 8-hour goal';
}

/// A goal delta without a zero minute part: `13m`, `1h`, `1h 12m`.
String _goalDelta(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}

/// One labelled date and time pair.
class _SessionSection extends StatelessWidget {
  const _SessionSection({
    required this.title,
    required this.enabled,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
  });

  final String title;

  /// Whether the rows open the date and time pickers.
  final bool enabled;

  final String date;
  final String time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.typography.emphasized.titleMedium.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        M3EList(
          itemCount: 2,
          variant: M3ECardVariant.filled,
          outerRadius: 16,
          innerRadius: 4,
          gap: 2,
          semanticsLabel: '$title date and time',
          onTap: enabled
              ? (index) => index == 0 ? onPickDate() : onPickTime()
              : null,
          itemBuilder: (context, index) {
            final isDate = index == 0;
            return M3EListItem(
              headline: isDate ? date : time,
              trailing: enabled
                  ? Icon(
                      isDate
                          ? M3EIcons.event_outlined
                          : M3EIcons.schedule_outlined,
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }
}

/// Why a session cannot be changed in Sleepy3.
///
/// The filled card uses the neutral `surfaceContainerHighest` / `onSurface`
/// pair so the notice recedes behind the `primaryContainer` hero. The lock sits
/// in a `surface` circle with an `onSurfaceVariant` icon and is centered against
/// the whole explanation, so it stays balanced when the message wraps. The 40dp
/// circle is a design decision; the card radius, padding and paired color roles
/// come from M3.
class _ReadOnlyCard extends StatelessWidget {
  const _ReadOnlyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return M3ECard(
      variant: M3ECardVariant.filled,
      color: scheme.surfaceContainerHighest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surface,
            ),
            child: Icon(
              M3EIcons.lock_outlined,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
          // 12dp separates the lock from the explanation, matching the health
          // notice below the fields.
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Read-only session',
                  style: theme.typography.emphasized.titleMedium.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.typography.baseline.bodyMedium.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline note that the session also lives in Google Health.
class _HealthNotice extends StatelessWidget {
  const _HealthNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = M3ETheme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(M3EIcons.cloud_sync_outlined, color: scheme.onSurfaceVariant),
        // 12dp separates the status icon from its message.
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: theme.typography.baseline.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

final _editorDate = DateFormat('EEE, MMM d, y', 'en_US');
final _editorDateNoYear = DateFormat('EEE, MMM d', 'en_US');
final _editorDateNoWeekday = DateFormat('MMM d, y', 'en_US');
final _spokenDate = DateFormat('EEEE, MMMM d, y', 'en_US');

String _formatEditorDate(DateTime value) => _editorDate.format(value.toLocal());

/// The compact date in a fact row.
///
/// The row's headline is a single line, so the year only appears when it is not
/// the current one; otherwise the weekday, month and day are enough and still
/// fit at 200 % text.
String _formatEditorDateRow(DateTime value, DateTime now) {
  final local = value.toLocal();
  return local.year == now.toLocal().year
      ? _editorDateNoYear.format(local)
      : _editorDateNoWeekday.format(local);
}

DateTime _withDate(DateTime value, DateTime date) =>
    DateTime(date.year, date.month, date.day, value.hour, value.minute);

DateTime _withTime(DateTime value, M3ETime time) =>
    DateTime(value.year, value.month, value.day, time.hour, time.minute);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
