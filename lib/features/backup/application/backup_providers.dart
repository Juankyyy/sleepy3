import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/application/health_sync_store_provider.dart';
import '../../sleep_tracking/application/sleep_tracking_providers.dart';
import '../data/file_picker_history_file_gateway.dart';
import 'sleep_history_transfer_service.dart';

/// The platform document picker used by Settings.
final sleepHistoryFileGatewayProvider = Provider<SleepHistoryFileGateway>(
  (ref) => const FilePickerHistoryFileGateway(),
);

/// Reads and writes Sleepy3 history files over the local stores.
final sleepHistoryTransferServiceProvider =
    Provider<SleepHistoryTransferService>((ref) {
      return SleepHistoryTransferService(
        ref.watch(sleepSessionStoreProvider),
        ref.watch(healthSyncStoreProvider),
        ref.watch(sleepClockProvider),
      );
    });
