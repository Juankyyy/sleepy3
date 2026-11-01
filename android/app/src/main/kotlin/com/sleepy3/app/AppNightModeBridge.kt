package com.sleepy3.app

import android.app.UiModeManager
import android.content.Context
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Mirrors the in-app theme into Android's per-app night mode.
 *
 * On Android 12+ the system resolves the launch (splash) window and its
 * resources with this persisted mode, so a pinned dark theme also gets a dark
 * splash on the next cold start. Older versions have no per-app night mode;
 * the call succeeds without doing anything there.
 */
object AppNightModeBridge {
    private const val CHANNEL = "com.sleepy3.app/app_night_mode"

    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "setApplicationNightMode") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                result.success(null)
                return@setMethodCallHandler
            }

            val nightMode = when (call.argument<String>("mode")) {
                "light" -> UiModeManager.MODE_NIGHT_NO
                "dark" -> UiModeManager.MODE_NIGHT_YES
                else -> UiModeManager.MODE_NIGHT_AUTO
            }

            try {
                context.getSystemService(UiModeManager::class.java)
                    ?.setApplicationNightMode(nightMode)
                result.success(null)
            } catch (error: Exception) {
                result.error("app_night_mode_failed", error.message, null)
            }
        }
    }
}
