import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/health_sync_store.dart';

/// Overridden in `main` with the Drift-backed sync metadata store.
final healthSyncStoreProvider = Provider<HealthSyncStore>((ref) {
  throw UnimplementedError(
    'healthSyncStoreProvider must be overridden with a HealthSyncStore',
  );
});
