import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the brand splash has finished or was skipped.
///
/// `SleepHomeScreen` waits for this before showing a Wake confirmation from
/// the ongoing notification, so a cold start does not open a dialog over the
/// splash.
final splashCompletedProvider =
    NotifierProvider<SplashCompletedController, bool>(
      SplashCompletedController.new,
    );

class SplashCompletedController extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;
}
