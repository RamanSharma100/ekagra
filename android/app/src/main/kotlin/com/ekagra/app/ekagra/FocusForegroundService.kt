package com.ekagra.app.ekagra

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.speech.tts.TextToSpeech
import java.util.Calendar
import java.util.Locale
import androidx.core.app.NotificationCompat

class FocusForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "ekagra_focus_channel_high"
        const val NOTIFICATION_ID = 1001

        const val CHANNEL_DIGEST_ID = "ekagra_digest_channel"
        const val NOTIFICATION_DIGEST_ID = 2002

        const val ACTION_START = "com.ekagra.app.action.START"
        const val ACTION_START_STANDBY = "com.ekagra.app.action.START_STANDBY"
        const val ACTION_UPDATE = "com.ekagra.app.action.UPDATE"
        const val ACTION_STOP = "com.ekagra.app.action.STOP"
        const val ACTION_TRIGGER_DIGEST = "com.ekagra.app.action.TRIGGER_DIGEST"

        const val EXTRA_SESSION_TITLE = "extra_session_title"
        const val EXTRA_REMAINING_SECONDS = "extra_remaining_seconds"
        const val EXTRA_BLOCKED_PACKAGES = "extra_blocked_packages"
        const val EXTRA_IS_PAUSED = "extra_is_paused"
        const val EXTRA_VOICE_ENABLED = "extra_voice_enabled"
    }

    private var sessionTitle: String = "Deep Work"
    private var remainingSeconds: Int = 0
    private var isSessionActive: Boolean = false
    private var isPaused: Boolean = false
    private val blockedPackages = mutableSetOf<String>()

    private var dbHelper: AppUsageDbHelper? = null
    private var shieldOverlayManager: ShieldOverlayManager? = null
    private val handler = Handler(Looper.getMainLooper())
    private var lastForegroundPackage: String? = null
    private var lastPackageStartTime: Long = System.currentTimeMillis()
    private var wakeLock: PowerManager.WakeLock? = null

    private var textToSpeech: TextToSpeech? = null
    private var isTtsReady: Boolean = false
    private var toneGenerator: ToneGenerator? = null
    private var voiceEnabled: Boolean = true
    private var lastVoiceAlertPackage: String? = null
    private var lastVoiceAlertTime: Long = 0L

    // Monitor foreground apps every 500ms
    private val monitorRunnable = object : Runnable {
        override fun run() {
            checkForegroundAppAndShield()
            handler.postDelayed(this, 500)
        }
    }

    // Tick remaining seconds every 1000ms
    private val timerRunnable = object : Runnable {
        override fun run() {
            if (isSessionActive && !isPaused && remainingSeconds > 0) {
                remainingSeconds--
                shieldOverlayManager?.updateSeconds(remainingSeconds)
                updateNotification()
                updateAppWidget()
            }
            checkScheduledMiddayDigest()
            handler.postDelayed(this, 1000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        dbHelper = AppUsageDbHelper(this)
        shieldOverlayManager = ShieldOverlayManager(this)
        createNotificationChannel()

        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
        } catch (_: Exception) {}

        try {
            textToSpeech = TextToSpeech(this) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    textToSpeech?.language = Locale.US
                    isTtsReady = true
                }
            }
        } catch (_: Exception) {}

        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
        wakeLock = powerManager?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Ekagra:FocusWakeLock")
        try {
            wakeLock?.acquire(4 * 60 * 60 * 1000L) // up to 4 hours
        } catch (_: Exception) {}

        // Default shielded apps
        blockedPackages.add("com.google.android.youtube")
        blockedPackages.add("com.instagram.android")
        blockedPackages.add("com.twitter.android")
        blockedPackages.add("com.reddit.frontpage")

        handler.post(monitorRunnable)
        handler.post(timerRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_STICKY

        when (intent.action) {
            ACTION_TRIGGER_DIGEST -> {
                sendMiddayDigestNotification()
            }
            ACTION_START -> {
                isSessionActive = true
                sessionTitle = intent.getStringExtra(EXTRA_SESSION_TITLE) ?: "Deep Work"
                remainingSeconds = intent.getIntExtra(EXTRA_REMAINING_SECONDS, 1500)
                isPaused = intent.getBooleanExtra(EXTRA_IS_PAUSED, false)
                voiceEnabled = intent.getBooleanExtra(EXTRA_VOICE_ENABLED, true)

                val packages = intent.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)
                if (packages != null && packages.isNotEmpty()) {
                    blockedPackages.clear()
                    blockedPackages.addAll(packages)
                }

                val notification = buildNotification()
                startForegroundSafely(notification)
                updateAppWidget()

                if (voiceEnabled) {
                    val mins = (remainingSeconds / 60).coerceAtLeast(1)
                    speakAnnouncement("Focus session started. Protecting your attention for $mins minutes.")
                }
            }
            ACTION_START_STANDBY -> {
                // Background tracker starts on app launch / boot
                if (!isSessionActive) {
                    val notification = buildNotification()
                    startForegroundSafely(notification)
                    updateAppWidget()
                }
            }
            ACTION_UPDATE -> {
                val newRemaining = intent.getIntExtra(EXTRA_REMAINING_SECONDS, -1)
                if (newRemaining >= 0) remainingSeconds = newRemaining

                val newTitle = intent.getStringExtra(EXTRA_SESSION_TITLE)
                if (!newTitle.isNullOrEmpty()) sessionTitle = newTitle

                if (intent.hasExtra(EXTRA_IS_PAUSED)) {
                    isPaused = intent.getBooleanExtra(EXTRA_IS_PAUSED, false)
                }

                if (intent.hasExtra(EXTRA_VOICE_ENABLED)) {
                    voiceEnabled = intent.getBooleanExtra(EXTRA_VOICE_ENABLED, true)
                }

                val packages = intent.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)
                if (packages != null && packages.isNotEmpty()) {
                    blockedPackages.clear()
                    blockedPackages.addAll(packages)
                }

                updateNotification()
                updateAppWidget()
            }
            ACTION_STOP -> {
                if (voiceEnabled && isSessionActive) {
                    speakAnnouncement("Focus session ended.")
                }
                isSessionActive = false
                remainingSeconds = 0
                shieldOverlayManager?.hideOverlay()
                updateNotification()
                updateAppWidget()
            }
        }

        return START_STICKY
    }

    private fun startForegroundSafely(notification: Notification) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: Exception) {
            try {
                startForeground(NOTIFICATION_ID, notification)
            } catch (_: Exception) {}
        }
    }

    private fun checkForegroundAppAndShield() {
        val currentPkg = getForegroundPackageName() ?: return

        // 1. Log app usage into SQLite database continuously
        val now = System.currentTimeMillis()
        if (lastForegroundPackage != null && lastForegroundPackage != currentPkg) {
            val durationSecs = ((now - lastPackageStartTime) / 1000).coerceAtLeast(1)
            var appLabel = lastForegroundPackage!!
            try {
                val pm = packageManager
                val info = pm.getApplicationInfo(lastForegroundPackage!!, 0)
                appLabel = pm.getApplicationLabel(info).toString()
            } catch (_: Exception) {}

            dbHelper?.recordAppUsage(lastForegroundPackage!!, appLabel, durationSecs)
            lastPackageStartTime = now
        } else if (lastForegroundPackage == currentPkg) {
            val elapsed = ((now - lastPackageStartTime) / 1000)
            if (elapsed >= 5) {
                var appLabel = currentPkg
                try {
                    val pm = packageManager
                    val info = pm.getApplicationInfo(currentPkg, 0)
                    appLabel = pm.getApplicationLabel(info).toString()
                } catch (_: Exception) {}

                dbHelper?.recordAppUsage(currentPkg, appLabel, elapsed)
                lastPackageStartTime = now
            }
        }
        lastForegroundPackage = currentPkg

        // 2. Shield Interception: If focus session is active and not paused, block restricted apps
        if (isSessionActive && !isPaused && remainingSeconds > 0) {
            val isRestricted = blockedPackages.contains(currentPkg) ||
                    (currentPkg == "com.google.android.youtube") ||
                    (currentPkg == "com.instagram.android") ||
                    (currentPkg == "com.twitter.android") ||
                    (currentPkg == "com.reddit.frontpage") ||
                    currentPkg.contains("youtube") ||
                    currentPkg.contains("instagram")

            if (isRestricted && currentPkg != packageName) {
                var appLabel = "Restricted App"
                try {
                    val pm = packageManager
                    val info = pm.getApplicationInfo(currentPkg, 0)
                    appLabel = pm.getApplicationLabel(info).toString()
                } catch (_: Exception) {}

                dbHelper?.recordBlockedAttempt(currentPkg, appLabel)

                // Play tone and speak warning if this is a new block event (throttled by 8s)
                val nowBlocked = System.currentTimeMillis()
                if (lastVoiceAlertPackage != currentPkg || (nowBlocked - lastVoiceAlertTime) > 8000) {
                    lastVoiceAlertPackage = currentPkg
                    lastVoiceAlertTime = nowBlocked

                    try {
                        toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP2, 180)
                    } catch (_: Exception) {}

                    if (voiceEnabled) {
                        speakAnnouncement("$appLabel is blocked. Returning to your focus.")
                    }
                }

                val canDrawOverlays = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Settings.canDrawOverlays(this)
                } else {
                    true
                }

                if (canDrawOverlays) {
                    // System WindowManager overlay directly covers YouTube
                    shieldOverlayManager?.showOverlay(appLabel, currentPkg, sessionTitle, remainingSeconds)
                } else {
                    // Fallback activity if overlay permission is not yet enabled
                    try {
                        val overlayIntent = Intent(this, BlockOverlayActivity::class.java).apply {
                            putExtra(BlockOverlayActivity.EXTRA_APP_NAME, appLabel)
                            putExtra(BlockOverlayActivity.EXTRA_PACKAGE_NAME, currentPkg)
                            putExtra(BlockOverlayActivity.EXTRA_REMAINING_SECONDS, remainingSeconds)
                            putExtra(BlockOverlayActivity.EXTRA_SESSION_TITLE, sessionTitle)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        startActivity(overlayIntent)
                    } catch (_: Exception) {}
                }
            } else {
                // Not in a restricted app -> hide overlay
                if (shieldOverlayManager?.isCurrentlyShowing() == true &&
                    currentPkg != shieldOverlayManager?.getBlockedPackage()) {
                    shieldOverlayManager?.hideOverlay()
                }
            }
        } else {
            shieldOverlayManager?.hideOverlay()
        }
    }

    private fun getForegroundPackageName(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return null
        val time = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(time - 15000, time)
        val event = UsageEvents.Event()
        var fgPackage: String? = null

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                fgPackage = event.packageName
            }
        }

        if (fgPackage == null) {
            val statsList = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 60000, time)
            if (!statsList.isNullOrEmpty()) {
                val mostRecent = statsList.maxByOrNull { it.lastTimeUsed }
                if (mostRecent != null && (time - mostRecent.lastTimeUsed) < 20000) {
                    fgPackage = mostRecent.packageName
                }
            }
        }
        return fgPackage
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Ekagra Focus Status",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Ongoing notification displaying live focus session countdown and shield protection"
                setShowBadge(true)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val digestChannel = NotificationChannel(
                CHANNEL_DIGEST_ID,
                "Ekagra Midday & 6-Hour Focus Digest",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Midday (12 PM) and 6-hour interval activity analysis with top time-consuming apps"
                setShowBadge(true)
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
            manager?.createNotificationChannel(digestChannel)
        }
    }

    private fun buildNotification(): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title: String
        val text: String

        if (isSessionActive && remainingSeconds > 0) {
            val mins = remainingSeconds / 60
            val secs = remainingSeconds % 60
            val timeText = String.format("%02d:%02d", mins, secs)

            title = "Ekagra Focus Active • $sessionTitle"
            text = if (isPaused) {
                "Paused • $timeText remaining"
            } else {
                "🛡️ Shield Active • $timeText remaining"
            }
        } else {
            title = "Ekagra Focus Companion"
            text = "Background activity tracker active • Ready for focus"
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        return builder.build()
    }

    private fun updateNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun updateAppWidget() {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val thisWidget = ComponentName(this, EkagraAppWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            if (allWidgetIds.isNotEmpty()) {
                val updateIntent = Intent(this, EkagraAppWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, allWidgetIds)
                    putExtra(EkagraAppWidgetProvider.EXTRA_TITLE, if (isSessionActive) sessionTitle else "Ready to Focus")
                    putExtra(EkagraAppWidgetProvider.EXTRA_SECONDS, if (isSessionActive) remainingSeconds else 0)
                    putExtra(EkagraAppWidgetProvider.EXTRA_PAUSED, isPaused)
                }
                sendBroadcast(updateIntent)
            }
        } catch (_: Exception) {}
    }

    private var lastDigestSentHourKey: String = ""
    private var lastDigestCheckTime: Long = 0L

    private fun checkScheduledMiddayDigest() {
        val now = System.currentTimeMillis()
        if (now - lastDigestCheckTime < 30000) return
        lastDigestCheckTime = now

        val cal = Calendar.getInstance()
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        val minute = cal.get(Calendar.MINUTE)

        // Trigger at 12:00 PM (hour 12) or every 6 hours (0, 6, 12, 18) when minute is within first 2 minutes of the hour
        if ((hour == 12 || hour % 6 == 0) && minute < 2) {
            val key = "${cal.get(Calendar.YEAR)}_${cal.get(Calendar.DAY_OF_YEAR)}_$hour"
            if (key != lastDigestSentHourKey) {
                lastDigestSentHourKey = key
                sendMiddayDigestNotification()
            }
        }
    }

    fun sendMiddayDigestNotification() {
        try {
            dbHelper?.syncFromUsageStatsManager(this)
            val usageList = dbHelper?.getDailyUsage() ?: emptyList()
            val totalSecs = usageList.fold(0L) { acc, m -> acc + (m["totalSeconds"] as? Long ?: 0L) }
            val totalMins = totalSecs / 60

            val topApp = usageList.firstOrNull()
            val topAppName = (topApp?.get("appName") as? String) ?: "Applications"
            val topMins = (topApp?.get("totalMinutes") as? Long) ?: 0L

            val openIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("open_midday_digest", true)
            }
            val pendingIntent = PendingIntent.getActivity(
                this,
                NOTIFICATION_DIGEST_ID,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val title = if (Calendar.getInstance().get(Calendar.HOUR_OF_DAY) == 12) {
                "📊 12:00 PM Midday Focus Digest"
            } else {
                "⏱️ 6-Hour Activity Analysis"
            }

            val summary = if (topMins > 0) {
                "Most time spent: $topAppName (${topMins}m). Total ${totalMins}m tracked."
            } else {
                "Midday check-in: Review your morning focus and top time consumers."
            }

            val inboxStyle = NotificationCompat.InboxStyle()
                .setBigContentTitle(title)
                .setSummaryText("Time Consumption Analysis")

            if (usageList.isNotEmpty()) {
                val count = minOf(4, usageList.size)
                for (i in 0 until count) {
                    val item = usageList[i]
                    val name = item["appName"] as? String ?: "App"
                    val mins = item["totalMinutes"] as? Long ?: 0L
                    inboxStyle.addLine("${i + 1}. $name • ${mins}m")
                }
            } else {
                inboxStyle.addLine("No heavy app usage recorded in this cycle.")
            }
            inboxStyle.addLine("👉 Tap to view full dashboard analysis & arm shield")

            val builder = NotificationCompat.Builder(this, CHANNEL_DIGEST_ID)
                .setContentTitle(title)
                .setContentText(summary)
                .setStyle(inboxStyle)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setDefaults(NotificationCompat.DEFAULT_ALL)

            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.notify(NOTIFICATION_DIGEST_ID, builder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun speakAnnouncement(text: String) {
        try {
            if (isTtsReady && textToSpeech != null) {
                textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "EkagraShieldVoice")
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        handler.removeCallbacks(monitorRunnable)
        handler.removeCallbacks(timerRunnable)
        shieldOverlayManager?.hideOverlay()
        try {
            toneGenerator?.release()
            toneGenerator = null
            textToSpeech?.stop()
            textToSpeech?.shutdown()
            textToSpeech = null
        } catch (_: Exception) {}
        try {
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (_: Exception) {}
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
