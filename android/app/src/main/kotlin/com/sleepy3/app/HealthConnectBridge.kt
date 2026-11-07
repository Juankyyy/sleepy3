package com.sleepy3.app

import android.content.Context
import android.os.RemoteException
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.SleepSessionRecord
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Exposes Health Connect record metadata that the Flutter `health` plugin does
 * not map to Dart.
 *
 * A Sleepy3 session without a local copy still needs its stable client record
 * id and version to be edited. The Dart side writes the new times with the next
 * version so Health Connect replaces the same record instead of creating a
 * duplicate.
 */
class HealthConnectBridge(
    private val context: Context,
    private val scope: CoroutineScope,
) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "readSleepSessionWriteToken" -> readSleepSessionWriteToken(call, result)
                "deleteSleepSession" -> deleteSleepSession(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun readSleepSessionWriteToken(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val recordId = call.argument<String>("healthRecordId")
        if (recordId.isNullOrBlank()) {
            result.success(null)
            return
        }

        scope.launch {
            val token = withContext(Dispatchers.IO) {
                try {
                    val client = HealthConnectClient.getOrCreate(context)
                    val record = client.readRecord(SleepSessionRecord::class, recordId).record
                    val metadata = record.metadata

                    // A record from another install (release vs debug) or from
                    // another app cannot be updated from this package.
                    if (metadata.dataOrigin.packageName != context.packageName) {
                        return@withContext null
                    }

                    val clientRecordId = metadata.clientRecordId
                    if (clientRecordId.isNullOrBlank()) {
                        return@withContext null
                    }

                    mapOf(
                        "clientRecordId" to clientRecordId,
                        "clientRecordVersion" to metadata.clientRecordVersion,
                    )
                } catch (error: Exception) {
                    Log.w(TAG, "Could not read the Health Connect record metadata", error)
                    null
                }
            }
            result.success(token)
        }
    }

    /**
     * Deletes one sleep record by UUID or by client id.
     *
     * The `health` plugin collapses every failure into `false`, which cannot
     * tell a record that is already gone from one this package is not allowed
     * to touch. Health Connect throws a different exception for each case, so
     * the Dart side can repair a stale id or explain the failure.
     */
    private fun deleteSleepSession(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val healthRecordId = call.argument<String>("healthRecordId")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
        val clientRecordId = call.argument<String>("clientRecordId")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }

        if (healthRecordId == null && clientRecordId == null) {
            result.success("failed")
            return
        }

        scope.launch {
            val status = withContext(Dispatchers.IO) {
                try {
                    val client = HealthConnectClient.getOrCreate(context)
                    client.deleteRecords(
                        recordType = SleepSessionRecord::class,
                        recordIdsList = listOfNotNull(healthRecordId),
                        clientRecordIdsList = listOfNotNull(clientRecordId),
                    )
                    "deleted"
                } catch (error: RemoteException) {
                    Log.w(TAG, "The sleep record no longer exists", error)
                    "notFound"
                } catch (error: SecurityException) {
                    Log.w(
                        TAG,
                        "This package cannot delete the sleep record",
                        error,
                    )
                    "permission"
                } catch (error: Exception) {
                    Log.w(TAG, "Could not delete the sleep record", error)
                    "failed"
                }
            }
            result.success(status)
        }
    }

    companion object {
        const val CHANNEL = "com.sleepy3.app/health_connect"
        private const val TAG = "Sleepy3HealthBridge"
    }
}
