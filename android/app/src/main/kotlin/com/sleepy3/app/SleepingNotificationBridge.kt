package com.sleepy3.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.RemoteViews
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Posts the ongoing sleep-status notification with a native card.
 *
 * The Flutter notification plugin does not expose RemoteViews, so this small
 * bridge owns the custom layout while the plugin keeps handling permission and
 * the daily reminder. The chronometer base is converted from wall-clock time to
 * SystemClock.elapsedRealtime(), which is the time base the view needs.
 */
class SleepingNotificationBridge(private val context: Context) {
    private var channel: MethodChannel? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, METHOD_CHANNEL).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "show" -> {
                        try {
                            show(call)
                            result.success(null)
                        } catch (error: Exception) {
                            result.error(
                                "sleeping_notification_failed",
                                error.message,
                                null,
                            )
                        }
                    }

                    "cancel" -> {
                        context.getSystemService(NotificationManager::class.java)
                            ?.cancel(NOTIFICATION_ID)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    /**
     * Routes a tap on the custom card back to Flutter when MainActivity is
     * reused. A cold start already opens Home, so there is nothing to do there.
     */
    fun handleIntent(intent: Intent?) {
        if (intent?.getBooleanExtra(EXTRA_OPEN_HOME, false) != true) return
        channel?.invokeMethod("opened", null)
        intent.removeExtra(EXTRA_OPEN_HOME)
    }

    private fun show(call: MethodCall) {
        val startedAtMillis = call.argument<Long>("startedAtMillis")
            ?: throw IllegalArgumentException("startedAtMillis is required")
        val title = call.argument<String>("title").orEmpty()
        val body = call.argument<String>("body").orEmpty()
        val ongoingLabel = call.argument<String>("ongoingLabel").orEmpty()
        val channelName = call.argument<String>("channelName") ?: "Sleep status"
        val channelDescription = call.argument<String>("channelDescription").orEmpty()

        createChannel(channelName, channelDescription)

        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setShowWhen(false)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setColor(context.getColor(R.color.notification_accent))
            .setContentIntent(openHomeIntent())

        if (ongoingLabel.isNotBlank()) {
            builder.setSubText(ongoingLabel)
        }

        val fontScale = context.resources.configuration.fontScale
        if (fontScale <= MAX_CUSTOM_FONT_SCALE) {
            try {
                val collapsed = RemoteViews(
                    context.packageName,
                    R.layout.notification_sleeping,
                )
                val expanded = RemoteViews(
                    context.packageName,
                    R.layout.notification_sleeping_big,
                )
                setCustomContent(collapsed, startedAtMillis, title, body)
                setCustomContent(expanded, startedAtMillis, title, body)
                builder
                    .setStyle(Notification.DecoratedCustomViewStyle())
                    .setCustomContentView(collapsed)
                    .setCustomBigContentView(expanded)
            } catch (_: Exception) {
                // The status matters more than the custom card: keep the
                // standard layout if a custom view cannot be inflated.
                useStandardBody(builder, body)
            }
        } else {
            // The custom card stops fitting its 64dp collapsed height at
            // large font scales; the system layout remains readable.
            useStandardBody(builder, body)
        }

        context.getSystemService(NotificationManager::class.java)
            ?.notify(NOTIFICATION_ID, builder.build())
    }

    private fun setCustomContent(
        views: RemoteViews,
        startedAtMillis: Long,
        title: String,
        body: String,
    ) {
        views.setTextViewText(R.id.notification_sleeping_title, title)
        views.setTextViewText(R.id.notification_sleeping_body, body)
        views.setChronometer(
            R.id.notification_sleeping_chronometer,
            chronometerBase(startedAtMillis),
            null,
            true,
        )
    }

    private fun useStandardBody(builder: Notification.Builder, body: String) {
        builder.setStyle(Notification.BigTextStyle().bigText(body))
    }

    private fun createChannel(name: String, description: String) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val notificationChannel = NotificationChannel(
            CHANNEL_ID,
            name,
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            this.description = description
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        manager.createNotificationChannel(notificationChannel)
    }

    private fun openHomeIntent(): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_OPEN_HOME
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_OPEN_HOME, true)
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * Converts the wall-clock session start to the elapsed-realtime base that
     * Chronometer expects, so reopening the app mid-session does not reset it.
     */
    private fun chronometerBase(startedAtMillis: Long): Long {
        val elapsedSinceStart = (System.currentTimeMillis() - startedAtMillis)
            .coerceAtLeast(0L)
        return SystemClock.elapsedRealtime() - elapsedSinceStart
    }

    companion object {
        private const val METHOD_CHANNEL = "com.sleepy3.app/sleeping_notification"
        private const val EXTRA_OPEN_HOME = "com.sleepy3.app.extra.OPEN_HOME"
        private const val ACTION_OPEN_HOME = "com.sleepy3.app.action.OPEN_HOME"
        private const val CHANNEL_ID = "sleep_status"
        private const val NOTIFICATION_ID = 1002
        private const val MAX_CUSTOM_FONT_SCALE = 1.2f
    }
}
