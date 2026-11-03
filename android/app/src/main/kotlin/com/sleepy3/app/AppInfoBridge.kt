package com.sleepy3.app

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Resolves the Android label of the app that wrote a Health Connect record.
 *
 * The `health` plugin only exposes the package name, but the session editor
 * should name the source app. A package lookup is cheap and only runs when the
 * user opens a read-only session.
 */
object AppInfoBridge {
    private const val CHANNEL = "com.sleepy3.app/app_info"

    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "appLabelForPackage" -> appLabelForPackage(context, call, result)
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun appLabelForPackage(
        context: Context,
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val packageName = call.argument<String>("packageName")?.trim()
        if (packageName.isNullOrEmpty()) {
            result.success(null)
            return
        }

        try {
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getApplicationInfo(
                    packageName,
                    PackageManager.ApplicationInfoFlags.of(0),
                )
            } else {
                context.packageManager.getApplicationInfo(packageName, 0)
            }
            result.success(context.packageManager.getApplicationLabel(info).toString())
        } catch (_: PackageManager.NameNotFoundException) {
            result.success(null)
        } catch (_: Exception) {
            result.success(null)
        }
    }
}
