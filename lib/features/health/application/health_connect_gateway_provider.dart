import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/health_connect_gateway.dart';

/// Overridden in `main` with the `health` plugin gateway.
final healthConnectGatewayProvider = Provider<HealthConnectGateway>((ref) {
  throw UnimplementedError(
    'healthConnectGatewayProvider must be overridden with a '
    'HealthConnectGateway',
  );
});
