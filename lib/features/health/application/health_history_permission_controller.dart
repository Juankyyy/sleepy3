import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/health_history_access.dart';
import 'health_connect_gateway_provider.dart';

/// Owns the Health Connect history permission and its 30-day fallback.
///
/// Every read goes through [HealthHistoryAccess]: when full history is not
/// authorized, the repositories only ask Health Connect for the last
/// [healthConnectHistoryLimit]. A platform failure is treated as a denial so a
/// missing permission can never break the history screen.
class HealthHistoryPermissionController extends Notifier<HealthHistoryAccess> {
  Future<bool>? _request;

  @override
  HealthHistoryAccess build() => HealthHistoryAccess.unknown;

  /// Re-reads the permission without showing a dialog.
  ///
  /// Used when the history loads and when the app returns to the foreground,
  /// because the user can change the grant in Health Connect settings.
  Future<HealthHistoryAccess> refresh() async {
    final granted = await _isAuthorized();
    if (!ref.mounted) return state;

    state = granted
        ? HealthHistoryAccess.authorized
        : HealthHistoryAccess.denied;
    return state;
  }

  /// Returns whether full history is available, asking for it when needed.
  ///
  /// An existing grant is reused without opening the dialog. Concurrent
  /// callers share one platform request, so a double tap cannot ask twice.
  Future<bool> ensureAuthorized() {
    final running = _request;
    if (running != null) return running;

    final future = _ensureAuthorized();
    _request = future;
    future.whenComplete(() {
      if (identical(_request, future)) _request = null;
    });
    return future;
  }

  Future<bool> _ensureAuthorized() async {
    if (await _isAuthorized()) {
      _set(HealthHistoryAccess.authorized);
      return true;
    }

    var granted = false;
    try {
      granted = await ref
          .read(healthConnectGatewayProvider)
          .requestHistoryPermission();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not request the Health Connect history permission: '
        '$error\n$stackTrace',
      );
    }

    _set(granted ? HealthHistoryAccess.authorized : HealthHistoryAccess.denied);
    return granted;
  }

  Future<bool> _isAuthorized() async {
    try {
      return await ref.read(healthConnectGatewayProvider).isHistoryAuthorized();
    } catch (error, stackTrace) {
      debugPrint(
        'Sleepy3: could not read the Health Connect history permission: '
        '$error\n$stackTrace',
      );
      return false;
    }
  }

  void _set(HealthHistoryAccess access) {
    if (!ref.mounted) return;
    state = access;
  }
}

final healthHistoryPermissionProvider =
    NotifierProvider<HealthHistoryPermissionController, HealthHistoryAccess>(
      HealthHistoryPermissionController.new,
    );
