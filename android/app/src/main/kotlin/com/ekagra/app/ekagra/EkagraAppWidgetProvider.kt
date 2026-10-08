package com.ekagra.app.ekagra

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class EkagraAppWidgetProvider : AppWidgetProvider() {

    companion object {
        const val EXTRA_TITLE = "extra_widget_title"
        const val EXTRA_SECONDS = "extra_widget_seconds"
        const val EXTRA_PAUSED = "extra_widget_paused"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidgetView(context, appWidgetManager, appWidgetId, "Ready to Focus", 0, false)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val title = intent.getStringExtra(EXTRA_TITLE) ?: "Deep Focus"
            val seconds = intent.getIntExtra(EXTRA_SECONDS, 0)
            val isPaused = intent.getBooleanExtra(EXTRA_PAUSED, false)

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS)

            if (appWidgetIds != null) {
                for (id in appWidgetIds) {
                    updateWidgetView(context, appWidgetManager, id, title, seconds, isPaused)
                }
            }
        }
    }

    private fun updateWidgetView(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        title: String,
        remainingSeconds: Int,
        isPaused: Boolean
    ) {
        val views = RemoteViews(context.packageName, R.layout.ekagra_app_widget)

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        if (remainingSeconds > 0) {
            val mins = remainingSeconds / 60
            val secs = remainingSeconds % 60
            val timeStr = String.format("%02d:%02d", mins, secs)

            views.setTextViewText(R.id.widget_session_title, title)
            views.setTextViewText(R.id.widget_time_text, timeStr)
            views.setTextViewText(R.id.widget_shield_status, if (isPaused) "PAUSED" else "SHIELD ACTIVE")
            views.setTextViewText(R.id.widget_action_btn, "Session in Progress • Tap to Open")
        } else {
            views.setTextViewText(R.id.widget_session_title, "Daily Productivity")
            views.setTextViewText(R.id.widget_time_text, "Ready")
            views.setTextViewText(R.id.widget_shield_status, "STANDBY")
            views.setTextViewText(R.id.widget_action_btn, "Tap to Start Focus Session")
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
