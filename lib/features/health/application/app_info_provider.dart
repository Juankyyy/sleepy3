import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/method_channel_app_info_gateway.dart';
import '../domain/app_info_gateway.dart';

/// The platform app-label gateway. Widget tests override this with a fake.
final appInfoGatewayProvider = Provider<AppInfoGateway>((ref) {
  return MethodChannelAppInfoGateway();
});

/// The Android label of the app that owns [packageName].
///
/// The family caches one lookup per package. Null means the app is not
/// installed or the platform could not resolve it; callers show a generic
/// "another app" label.
final appLabelProvider = FutureProvider.family<String?, String>((
  ref,
  packageName,
) {
  return ref.watch(appInfoGatewayProvider).appLabelForPackage(packageName);
});
