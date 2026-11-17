/// Opens an external link, such as the release page or the APK download.
abstract interface class UpdateLinkLauncher {
  Future<bool> open(Uri uri);
}
