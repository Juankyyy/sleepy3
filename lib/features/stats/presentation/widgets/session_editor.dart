import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/time/clock_format.dart';
import '../../../health/domain/sleep_data_source.dart';
import '../../../sleep_tracking/application/sleep_session_edit_service.dart';
import '../../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../../../sleep_tracking/domain/session_edit.dart';
import '../../../sleep_tracking/domain/sleep_duration.dart';
import '../../../sleep_tracking/domain/sleep_session.dart';

/// Opens the session editor for one closed session.
///
/// The editor is a full-screen dialog on compact windows and a basic dialog on
/// medium and expanded ones, matching the M3 adaptive dialog pattern. A session
/// that can only be deleted (a Google Health record without a local copy) uses
/// a basic dialog because it has no form to fill in.
Future<SleepSessionEditResult?> showSessionEditor(
  BuildContext context, {
  required SleepSession session,
  required SleepDataSource source,
  required SessionEditAccess access,
}) async {
  final dialogController = M3EDialogController();
  final editorKey = GlobalKey<SessionEditorState>();

  try {
    if (access == SessionEditAccess.deleteOnly) {
      return await M3EDialog.show<SleepSessionEditResult>(
        context,
        dialog: M3EDialog(
          title: 'Edit session',
          content: SessionEditor(
            key: editorKey,
            session: session,
            source: source,
            access: access,
          ),
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

    return await M3EDialog.showAdaptive<SleepSessionEditResult>(
      context,
      title: 'Edit session',
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
    if (_saving || _deleting) return;

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
    final result = await ref
        .read(sleepTrackingControllerProvider.notifier)
        .deleteClosedSession(widget.session);
    if (!mounted) return;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_canEdit) ...[
          _DurationSummary(
            duration: duration,
            endedAt: _endedAt,
            spokenDate: _spokenDate.format(_endedAt),
          ),
          const SizedBox(height: 24),
          _SessionSection(
            title: 'Fell asleep',
            date: _formatEditorDate(_startedAt),
            time: formatSessionTime(
              _startedAt,
              use24HourFormat: use24HourFormat,
            ),
            onPickDate: _pickStartDate,
            onPickTime: _pickStartTime,
          ),
          const SizedBox(height: 24),
          _SessionSection(
            title: 'Woke up',
            date: _formatEditorDate(_endedAt),
            time: formatSessionTime(_endedAt, use24HourFormat: use24HourFormat),
            onPickDate: _pickEndDate,
            onPickTime: _pickEndTime,
          ),
        ] else ...[
          Text(
            'This Google Health record has no local copy. You can delete it, '
            'but its times cannot be edited here.',
            style: theme.typography.baseline.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _DurationSummary(
            duration: duration,
            endedAt: _endedAt,
            spokenDate: _spokenDate.format(_endedAt),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatEditorDate(_startedAt)} at '
            '${formatSessionTime(_startedAt, use24HourFormat: use24HourFormat)}'
            ' to ${_formatEditorDate(_endedAt)} at '
            '${formatSessionTime(_endedAt, use24HourFormat: use24HourFormat)}',
            style: theme.typography.baseline.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_showsHealthNotice) ...[
          const SizedBox(height: 16),
          _HealthNotice(
            message: widget.source == SleepDataSource.healthConnect
                ? 'This night is stored in Google Health. Saving updates the '
                      'Health Connect record.'
                : 'This night is also in Google Health. Saving updates both '
                      'copies.',
          ),
        ],
        if (_errors.isNotEmpty) ...[
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
    );
  }
}

/// Duration and wake day, kept in sync with the draft.
class _DurationSummary extends StatelessWidget {
  const _DurationSummary({
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
      label: '${formatSpokenSleepDuration(duration)}, woke $spokenDate',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatSleepDuration(duration),
              style: theme.typography.emphasized.headlineSmall.copyWith(
                color: scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Woke ${_formatEditorDate(endedAt)}',
              style: theme.typography.baseline.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One labelled date and time pair.
class _SessionSection extends StatelessWidget {
  const _SessionSection({
    required this.title,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
  });

  final String title;
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
          onTap: (index) => index == 0 ? onPickDate() : onPickTime(),
          itemBuilder: (context, index) {
            final isDate = index == 0;
            return M3EListItem(
              headline: isDate ? 'Date' : 'Time',
              supportingText: isDate ? date : time,
              trailing: Icon(
                isDate ? M3EIcons.event_outlined : M3EIcons.schedule_outlined,
              ),
            );
          },
        ),
      ],
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
final _spokenDate = DateFormat('EEEE, MMMM d, y', 'en_US');

String _formatEditorDate(DateTime value) => _editorDate.format(value.toLocal());

DateTime _withDate(DateTime value, DateTime date) =>
    DateTime(date.year, date.month, date.day, value.hour, value.minute);

DateTime _withTime(DateTime value, M3ETime time) =>
    DateTime(value.year, value.month, value.day, time.hour, time.minute);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
