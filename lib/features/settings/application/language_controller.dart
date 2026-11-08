import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_language.dart';
import 'settings_providers.dart';

export 'settings_providers.dart';

/// Owns the interface language and persists changes in order.
///
/// The state updates immediately, so every localized string rebuilds on the
/// next frame. A failed write is logged but does not revert the visible
/// choice, matching how session writes behave.
class LanguageController extends Notifier<AppLanguage> {
  Future<void> _writeQueue = Future<void>.value();

  @override
  AppLanguage build() => ref.watch(initialLanguageProvider);

  Future<void> setLanguage(AppLanguage language) async {
    if (language == state) return;
    state = language;

    final store = ref.read(settingsStoreProvider);
    final next = _writeQueue
        .then((_) => store.saveLanguage(language))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint(
            'Sleepy3: could not persist the language: $error\n$stackTrace',
          );
        });
    _writeQueue = next;
    await next;
  }
}

final languageControllerProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);
