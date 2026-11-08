import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/time/clock_format.dart';
import '../../../../l10n/l10n.dart';
import '../../../health/domain/sleep_data_source.dart';
import '../../../sleep_tracking/application/sleep_session_edit_service.dart';
import '../../../sleep_tracking/application/sleep_tracking_controller.dart';
import '../../../sleep_tracking/domain/new_session_window.dart';
import '../../../sleep_tracking/domain/session_edit.dart';
import 'session_form_parts.dart';

/// Opens the editor for a session the user adds by hand.
///
/// The form starts with the last typical night's window and validates the
/// draft with the same rules as the session editor. The result is null when
/// the user closes the dialog without saving.
Future<SleepSessionEditResult?> showNewSessionEditor(
  BuildContext context, {
  required SleepDataSource source,
}) async {
  final l10n = context.l10n;
  final dialogController = M3EDialogController(
    discardLabels: M3EDialogDiscardLabels(
      title: l10n.discardChangesTitle,
      keepLabel: l10n.keepEditing,
      discardLabel: l10n.discard,
    ),
  );
  final editorKey = GlobalKey<NewSessionEditorState>();

  try {
    return await M3EDialog.showAdaptive<SleepSessionEditResult>(
      context,
      title: l10n.newSessionTitle,
      content: NewSessionEditor(
        key: editorKey,
        source: source,
        dialogController: dialogController,
      ),
      confirmLabel: l10n.addAction,
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

/// The form shown by [showNewSessionEditor].
///
/// It owns the draft, validates it against the history, and sends it through
/// the tracking controller. Closing after a successful save returns a
/// [SleepSessionEditResult] to the FAB so it can explain a pending upload.
class NewSessionEditor extends ConsumerStatefulWidget {
  const NewSessionEditor({
    super.key,
    required this.source,
    this.dialogController,
  });

  final SleepDataSource source;

  /// Keeps the discard confirmation in sync with the draft.
  final M3EDialogController? dialogController;

  @override
  ConsumerState<NewSessionEditor> createState() => NewSessionEditorState();
}

class NewSessionEditorState extends ConsumerState<NewSessionEditor> {
  late final DateTime _initialStartedAt;
  late final DateTime _initialEndedAt;
  late DateTime _startedAt;
  late DateTime _endedAt;
  List<SessionEditError> _errors = const [];
  bool _saving = false;

  bool get _isDirty =>
      _startedAt != _initialStartedAt || _endedAt != _initialEndedAt;

  @override
  void initState() {
    super.initState();
    final window = defaultNewSessionWindow(ref.read(sleepClockProvider)());
    _initialStartedAt = window.startedAt;
    _initialEndedAt = window.endedAt;
    _startedAt = window.startedAt;
    _endedAt = window.endedAt;
  }

  /// Validates and saves the draft. Called by the adaptive dialog's Add action.
  Future<void> save() async {
    if (_saving) return;

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
        .createClosedSession(startedAt: _startedAt, endedAt: _endedAt);
    if (!mounted) return;

    setState(() => _saving = false);

    switch (result.status) {
      case SleepSessionEditStatus.saved:
      case SleepSessionEditStatus.savedPendingSync:
        _close(result);
      case SleepSessionEditStatus.permissionNeeded:
        if (result.hasLocalChange) {
          // The local copy is already saved; the caller explains the pending
          // sync. This path is defensive because creation saves locally first.
          _close(result);
        } else {
          final l10n = context.l10n;
          await _showError(
            title: l10n.healthNeedsPermissionTitle,
            message: l10n.allowWriteHealth,
          );
        }
      case SleepSessionEditStatus.deleted:
      case SleepSessionEditStatus.failed:
        final error = result.error;
        if (error is SessionEditError) {
          setState(() => _errors = [error]);
          return;
        }
        final l10n = context.l10n;
        await _showError(
          title: l10n.couldNotAdd,
          message: l10n.couldNotAddBody,
        );
    }
  }

  List<SessionEditError> _validate() {
    final state = ref.read(sleepTrackingControllerProvider);
    return validateSessionEdit(
      draft: SessionEditDraft(startedAt: _startedAt, endedAt: _endedAt),
      now: ref.read(sleepClockProvider)(),
      otherClosedSessions: state.closedSessions,
      openSession: state.openSession,
    );
  }

  Future<void> _pickStartDate() async {
    if (_saving) return;
    final now = ref.read(sleepClockProvider)();
    final picked = await M3EDatePicker.show(
      context,
      initialDate: _startedAt,
      firstDate: DateTime(1970),
      lastDate: dateOnly(now),
      currentDate: now,
      helpText: context.l10n.selectSleepDate,
    );
    if (picked == null || !mounted) return;

    _setDraft(withSessionDate(_startedAt, picked), _endedAt);
  }

  Future<void> _pickEndDate() async {
    if (_saving) return;
    final now = ref.read(sleepClockProvider)();
    final picked = await M3EDatePicker.show(
      context,
      initialDate: _endedAt,
      firstDate: DateTime(1970),
      lastDate: dateOnly(now),
      currentDate: now,
      helpText: context.l10n.selectWakeDate,
    );
    if (picked == null || !mounted) return;

    _setDraft(_startedAt, withSessionDate(_endedAt, picked));
  }

  Future<void> _pickStartTime() async {
    if (_saving) return;
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
    if (_saving) return;
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
      // Validate as soon as the draft changes so an impossible night is
      // explained before the user taps Add. The initial window is not shown as
      // an error on open.
      _errors = _validate();
    });
    widget.dialogController?.hasUnsavedChanges = _isDirty;
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
    final l10n = context.l10n;
    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);
    final duration = _endedAt.difference(_startedAt);
    final now = ref.read(sleepClockProvider)();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SessionHero(duration: duration, endedAt: _endedAt),
        const SizedBox(height: 24),
        SessionTimeSection(
          title: l10n.fellAsleep,
          enabled: !_saving,
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
          enabled: !_saving,
          date: formatSessionEditorDateRow(_endedAt, now, l10n.localeName),
          time: formatSessionTime(
            _endedAt,
            use24HourFormat: use24HourFormat,
            localeName: l10n.localeName,
          ),
          onPickDate: _pickEndDate,
          onPickTime: _pickEndTime,
        ),
        if (widget.source == SleepDataSource.healthConnect) ...[
          const SizedBox(height: 16),
          SessionHealthNotice(message: l10n.healthNoticeAdded),
        ],
        if (_errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          SessionErrors(errors: _errors),
        ],
      ],
    );
  }
}
