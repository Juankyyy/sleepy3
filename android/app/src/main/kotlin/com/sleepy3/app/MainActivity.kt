package com.sleepy3.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/**
 * Flutter entry point.
 *
 * Health Connect permission requests need a ComponentActivity to register the
 * permission contract, so this must stay a FlutterFragmentActivity.
 */
class MainActivity : FlutterFragmentActivity() {
    private val healthBridgeScope =
        CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        HealthConnectBridge(applicationContext, healthBridgeScope)
            .register(flutterEngine.dartExecutor.binaryMessenger)
        AppInfoBridge.register(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )
        AppNightModeBridge.register(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun onDestroy() {
        healthBridgeScope.cancel()
        super.onDestroy()
    }
}
