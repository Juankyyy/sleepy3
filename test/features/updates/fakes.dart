import 'dart:async';

import 'package:sleepy3/features/updates/domain/app_release.dart';
import 'package:sleepy3/features/updates/domain/app_release_gateway.dart';
import 'package:sleepy3/features/updates/domain/update_link_launcher.dart';

/// A scripted release gateway for widget and controller tests.
class FakeAppReleaseGateway implements AppReleaseGateway {
  FakeAppReleaseGateway([this.next]);

  factory FakeAppReleaseGateway.upToDate(String version) {
    return FakeAppReleaseGateway(testRelease(version));
  }

  AppRelease? next;
  Object? error;
  Completer<AppRelease>? pending;
  int calls = 0;

  @override
  Future<AppRelease> fetchLatest() {
    calls++;

    final error = this.error;
    if (error != null) return Future<AppRelease>.error(error);

    final pending = this.pending;
    if (pending != null) return pending.future;

    final next = this.next;
    if (next == null) {
      return Future<AppRelease>.error(StateError('No release configured'));
    }
    return Future<AppRelease>.value(next);
  }
}

class FakeUpdateLinkLauncher implements UpdateLinkLauncher {
  FakeUpdateLinkLauncher({this.result = true});

  bool result;
  final List<Uri> uris = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    uris.add(uri);
    return result;
  }
}

AppRelease testRelease(String version, {String? notes}) {
  final tag = 'v$version';
  return AppRelease(
    tag: tag,
    version: version,
    name: '$tag - The Test Update',
    pageUrl: Uri.parse('https://github.com/Juankyyy/sleepy3/releases/tag/$tag'),
    apkUrl: Uri.parse(
      'https://github.com/Juankyyy/sleepy3/releases/download/$tag/'
      'sleepy3-$tag.apk',
    ),
    notes:
        notes ??
        '''
Test release $version.

## Highlights

- First change.
- Second change.

**Full changelog**: https://example.com/compare/$tag
''',
  );
}
