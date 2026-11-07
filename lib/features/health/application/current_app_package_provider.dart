import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Package name of the running build.
///
/// Health Connect only lets the package that wrote a record edit or delete it,
/// so this is the identity used for write access. [main] overrides it with
/// `PackageInfo.packageName`; the release id is the default so tests and a
/// failed platform lookup keep the release behaviour.
final currentAppPackageProvider = Provider<String>((ref) => 'com.sleepy3.app');
