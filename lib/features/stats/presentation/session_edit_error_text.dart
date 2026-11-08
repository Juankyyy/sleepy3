import '../../../l10n/l10n.dart';
import '../../sleep_tracking/domain/session_edit.dart';

/// The localized explanation of one session validation error.
extension SessionEditErrorText on AppLocalizations {
  String sessionEditError(SessionEditError error) {
    return switch (error) {
      SessionEditError.endNotAfterStart => errorEndNotAfterStart,
      SessionEditError.tooShort => errorTooShort,
      SessionEditError.tooLong => errorTooLong,
      SessionEditError.startInTheFuture => errorStartInTheFuture,
      SessionEditError.endInTheFuture => errorEndInTheFuture,
      SessionEditError.overlapsClosedSession => errorOverlapsClosedSession,
      SessionEditError.overlapsOpenSession => errorOverlapsOpenSession,
    };
  }
}
