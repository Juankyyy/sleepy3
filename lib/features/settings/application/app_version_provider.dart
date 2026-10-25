import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_version.dart';

/// Overridden in `main` with the installed version.
///
/// Null means the platform could not provide it; the Settings screen then
/// hides the version row instead of showing an invented number.
final appVersionProvider = Provider<AppVersion?>((ref) => null);
