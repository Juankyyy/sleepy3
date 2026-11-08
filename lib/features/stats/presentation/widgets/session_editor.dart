import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/time/clock_format.dart';
import '../../../../l10n/l10n.dart';
import '../../../health/application/app_info_provider.dart';
import '../../../health/application/current_app_package_provider.dart';
import '../../../health/application/health_connect_gateway_provider.dart';
import '../../../health/domain/sleep_data_source.dart';
import '../../../health/domain/sleepy3_health_source.dart';
import '../../../sleep_tracking/application/sleep_session_edit_service.dart';
import '../../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../../../sleep_tracking/domain/session_edit.dart';
import '../../../sleep_tracking/domain/sleep_session.dart';
import 'session_form_parts.dart';

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

  final l10n = context.l10n;
  final dialogController = M3EDialogController(
    discardLabels: M3EDialogDiscardLabels(
      title: l10n.discardChangesTitle,
      keepLabel: l10n.keepEditing,
      discardLabel: l10n.discard,
    ),
  );
  final editorKey = GlobalKey<SessionEditorState>();

  try {
    return await M3EDialog.showAdaptive<SleepSessionEditResult>(
      context,
      title: l10n.sessionTitle,
      content: SessionEditor(
        key: editorKey,
        session: session,
        source: source,
        access: access,
        dialogController: dialogController,
      ),
      confirmLabel: l10n.save,
      dismissLabel: l10n.cancel,
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
  final l10n = context.l10n;
  final isCompact =
      MediaQuery.sizeOf(context).width < theme.dialogTheme.compactBreakpoint;

  if (isCompact) {
    return M3EDialog.showFullScreen<SleepSessionEditResult>(
      context,
      title: l10n.sessionTitle,
      body: SingleChildScrollView(child: content),
    );
  }

  return M3EDialog.show<SleepSessionEditResult>(
    context,
    dialog: M3EDialog(
      title: l10n.sessionTitle,
      content: content,
      actions: [
        M3EButton(
          style: M3EButtonStyle.text,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
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

    final l10n = context.l10n;
    if (result.status == SleepSessionEditStatus.permissionNeeded) {
      if (result.hasLocalChange) {
        // The local copy is already saved; Stats explains the pending sync.
        _close(result);
      } else {
        await _showError(
          title: l10n.healthNeedsPermissionTitle,
          message: l10n.allowWriteHealth,
        );
      }
      return;
    }

    final error = result.error;
    if (error is SessionEditError) {
      setState(() => _errors = [error]);
      return;
    }

    await _showError(title: l10n.couldNotSave, message: l10n.couldNotSaveBody);
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
      helpText: context.l10n.selectSleepDate,
    );
    if (picked == null || !mounted) return;

    _setDraft(withSessionDate(_startedAt, picked), _endedAt);
  }

  Future<void> _pickEndDate() async {
    if (!_canEdit) return;
    final picked = await M3EDatePicker.show(
      context,
      initialDate: _endedAt,
      firstDate: DateTime(1970),
      lastDate: _lastPickableDate,
      currentDate: ref.read(sleepClockProvider)(),
      helpText: context.l10n.selectWakeDate,
    );
    if (picked == null || !mounted) return;

    _setDraft(_startedAt, withSessionDate(_endedAt, picked));
  }

  Future<void> _pickStartTime() async {
    if (!_canEdit) return;
    final picked = await M3ETimePicker.show(
      context,
      initialTime: M3ETime(hour: _startedAt.hour, minute: _startedAt.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      helpText: context.l10n.selectSleepTime,
    );
    if (picked == null || !mounted) return;

    _setDraft(withSessionTime(_startedAt, picked), _endedAt);
  }

  Future<void> _pickEndTime() async {
    if (!_canEdit) return;
    final picked = await M3ETimePicker.show(
      context,
      initialTime: M3ETime(hour: _endedAt.hour, minute: _endedAt.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      helpText: context.l10n.selectWakeTime,
    );
    if (picked == null || !mounted) return;

    _setDraft(_startedAt, withSessionTime(_endedAt, picked));
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
    final today = dateOnly(now);
    final start = dateOnly(_startedAt);
    final end = dateOnly(_endedAt);
    final latest = start.isAfter(end) ? start : end;
    return latest.isAfter(today) ? latest : today;
  }

  Future<void> _confirmDelete() async {
    if (!_canEdit || _saving || _deleting) return;

    final l10n = context.l10n;
    final confirmed = await M3EDialog.show<bool>(
      context,
      dialog: M3EDialog(
        title: l10n.deleteSessionTitle,
        content: Text(_deleteMessage(l10n)),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
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
        final messageL10n = context.l10n;
        await _showError(
          title: messageL10n.healthNeedsPermissionTitle,
          message: messageL10n.allowWriteHealth,
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

    final errorL10n = context.l10n;
    await _showError(
      title: result.status == SleepSessionEditStatus.permissionNeeded
          ? errorL10n.healthNeedsPermissionTitle
          : errorL10n.couldNotDelete,
      message: result.status == SleepSessionEditStatus.permissionNeeded
          ? errorL10n.allowDeleteHealth
          : errorL10n.couldNotDeleteBody,
    );
  }

  Future<SleepSessionEditResult> _delete() {
    return ref
        .read(sleepTrackingControllerProvider.notifier)
        .deleteClosedSession(widget.session);
  }

  Future<bool?> _askToAllowDelete() {
    final l10n = context.l10n;
    return M3EDialog.show<bool>(
      context,
      dialog: M3EDialog(
        title: l10n.healthNeedsPermissionTitle,
        content: Text(l10n.allowDeleteHealthShort),
        actions: [
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.close),
          ),
          M3EButton(
            style: M3EButtonStyle.text,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.allow),
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

  String _deleteMessage(AppLocalizations l10n) {
    if (widget.source == SleepDataSource.healthConnect) {
      return l10n.deleteMessageHealth;
    }
    if (widget.session.healthRecordId != null) {
      return l10n.deleteMessageHealthAndLocal;
    }
    return l10n.deleteMessageLocal;
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
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = M3ETheme.of(context).colorScheme;
    final l10n = context.l10n;
    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);
    final duration = _endedAt.difference(_startedAt);
    final canEdit = _canEdit;
    final now = ref.read(sleepClockProvider)();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SessionHero(duration: duration, endedAt: _endedAt),
        if (!canEdit) ...[
          const SizedBox(height: 24),
          _ReadOnlyCard(message: _readOnlyMessage(l10n)),
        ],
        const SizedBox(height: 24),
        SessionTimeSection(
          title: l10n.fellAsleep,
          enabled: canEdit,
          date: formatSessionEditorDateRow(_startedAt, now, l10n.localeName),
          time: formatSessionTime(
            _startedAt,
            use24HourFormat: use24HourFormat,
            localeName: l10n.localeName,
          ),
          onPickDate: _pickStartDate,
          onPickTime: _pickStartTime,
        ),
        const SizedBox(height: 24),
        SessionTimeSection(
          title: l10n.wokeUp,
          enabled: canEdit,
          date: formatSessionEditorDateRow(_endedAt, now, l10n.localeName),
          time: formatSessionTime(
            _endedAt,
            use24HourFormat: use24HourFormat,
            localeName: l10n.localeName,
          ),
          onPickDate: _pickEndDate,
          onPickTime: _pickEndTime,
        ),
        if (canEdit && _showsHealthNotice) ...[
          const SizedBox(height: 16),
          SessionHealthNotice(
            message: widget.source == SleepDataSource.healthConnect
                ? l10n.healthNoticeStored
                : l10n.healthNoticeBoth,
          ),
        ],
        if (canEdit && _errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          SessionErrors(errors: _errors),
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
              child: Text(l10n.deleteSessionAction),
            ),
          ),
        ],
      ],
    );
  }

  /// Why the session is read-only, using the source app when Android can
  /// resolve its label.
  String _readOnlyMessage(AppLocalizations l10n) {
    final session = widget.session;
    final currentPackage = ref.read(currentAppPackageProvider);
    final otherBuild = isOtherSleepy3Build(session.sourceId, currentPackage);

    if (widget.source == SleepDataSource.healthConnect) {
      if (otherBuild) {
        return l10n.readOnlyOtherBuild(_otherBuildName(l10n));
      }
      if (isSleepy3HealthRecord(session.sourceId)) {
        return l10n.readOnlySleepy3;
      }
      return l10n.readOnlyOtherApp(_sourceAppLabel(l10n));
    }

    if (widget.source == SleepDataSource.local && session.isDownloaded) {
      if (otherBuild) {
        return l10n.readOnlyDownloadedOtherBuild(_otherBuildName(l10n));
      }
      if (isSleepy3HealthRecord(session.sourceId)) {
        return l10n.readOnlyDownloadedSleepy3;
      }
      if (session.sourceId != null) {
        return l10n.readOnlyDownloadedOtherApp(_sourceAppLabel(l10n));
      }
      return l10n.readOnlyDownloadedUnknown;
    }

    return l10n.readOnlySleepy3;
  }

  String _otherBuildName(AppLocalizations l10n) {
    final sourceId = widget.session.sourceId;
    final label = sourceId == null
        ? null
        : ref.watch(appLabelProvider(sourceId)).asData?.value;
    return label ?? l10n.otherSleepy3Build;
  }

  String _sourceAppLabel(AppLocalizations l10n) {
    final sourceId = widget.session.sourceId;
    if (sourceId == null) return l10n.anotherAppLower;
    final label = ref.watch(appLabelProvider(sourceId)).asData?.value;
    return label ?? l10n.anotherAppLower;
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
                  context.l10n.readOnlySession,
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
