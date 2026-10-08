package com.ekagra.app.ekagra

import android.app.AppOpsManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.speech.tts.TextToSpeech
import java.util.Locale
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val APPS_CHANNEL = "com.ekagra.app/device_apps"
    private val SHIELD_CHANNEL = "com.ekagra.app/app_shield"

    private lateinit var dbHelper: AppUsageDbHelper
    private var pendingOpenDigest: Boolean = false

    private var textToSpeech: TextToSpeech? = null
    private var isTtsReady: Boolean = false
    private var toneGenerator: ToneGenerator? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent?.getBooleanExtra("open_midday_digest", false) == true) {
            pendingOpenDigest = true
        }

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

        startStandbyBackgroundService()
    }

    override fun onDestroy() {
        try {
            toneGenerator?.release()
            toneGenerator = null
            textToSpeech?.stop()
            textToSpeech?.shutdown()
            textToSpeech = null
        } catch (_: Exception) {}
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra("open_midday_digest", false)) {
            pendingOpenDigest = true
        }
    }

    private fun startStandbyBackgroundService() {
        try {
            val serviceIntent = Intent(this, FocusForegroundService::class.java).apply {
                action = FocusForegroundService.ACTION_START_STANDBY
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(this, serviceIntent)
            } else {
                startService(serviceIntent)
            }
        } catch (_: Exception) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        dbHelper = AppUsageDbHelper(this)

        // 1. Channel for Querying Installed Applications
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        val pm = packageManager
                        val installedList = mutableListOf<Map<String, Any>>()
                        val seenPackages = mutableSetOf<String>()

                        // 1. Query all apps that appear in the launcher (YouTube, Chrome, Gmail, Clock, etc.)
                        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                            addCategory(Intent.CATEGORY_LAUNCHER)
                        }
                        val launchables = pm.queryIntentActivities(mainIntent, 0)
                        for (resolveInfo in launchables) {
                            val pkgName = resolveInfo.activityInfo.packageName
                            if (pkgName != packageName && !seenPackages.contains(pkgName)) {
                                seenPackages.add(pkgName)
                                val name = resolveInfo.loadLabel(pm).toString()
                                installedList.add(
                                    mapOf(
                                        "name" to name,
                                        "packageName" to pkgName,
                                        "isSystem" to false
                                    )
                                )
                            }
                        }

                        // 2. Query other installed non-system packages
                        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                        for (appInfo in packages) {
                            val pkgName = appInfo.packageName
                            if (pkgName != packageName && !seenPackages.contains(pkgName)) {
                                val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                                val isUpdatedSystem = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                                val isNotable = pkgName.contains("youtube") || pkgName.contains("chrome") ||
                                        pkgName.contains("browser") || pkgName.contains("social")

                                if (!isSystem || isUpdatedSystem || isNotable) {
                                    seenPackages.add(pkgName)
                                    val name = pm.getApplicationLabel(appInfo).toString()
                                    installedList.add(
                                        mapOf(
                                            "name" to name,
                                            "packageName" to pkgName,
                                            "isSystem" to isSystem
                                        )
                                    )
                                }
                            }
                        }

                        // Sort alphabetically
                        installedList.sortBy { (it["name"] as? String)?.lowercase() ?: "" }
                        result.success(installedList)
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", e.message, null)
                    }
                }
                "getDailyAppUsage" -> {
                    try {
                        // Sync real usage from Android UsageStatsManager into SQLite
                        dbHelper.syncFromUsageStatsManager(this)
                        val usageList = dbHelper.getDailyUsage()
                        result.success(usageList)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Channel for App Shield, Foreground Service, Notifications & Widget
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHIELD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsagePermission" -> {
                    val granted = isUsageAccessGranted()
                    result.success(granted)
                }
                "requestUsagePermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                "checkOverlayPermission" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(context)
                    } else {
                        true
                    }
                    result.success(granted)
                }
                "requestOverlayPermission" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                "checkNotificationPermission" -> {
                    val granted = if (Build.VERSION.SDK_INT >= 33) {
                        ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }
                    result.success(granted)
                }
                "requestNotificationPermission" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= 33) {
                            requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
                        } else {
                            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                "getOnboardingCompleted" -> {
                    val prefs = getSharedPreferences("ekagra_prefs", Context.MODE_PRIVATE)
                    result.success(prefs.getBoolean("onboarding_completed", false))
                }
                "setOnboardingCompleted" -> {
                    val completed = call.argument<Boolean>("completed") ?: true
                    val prefs = getSharedPreferences("ekagra_prefs", Context.MODE_PRIVATE)
                    prefs.edit().putBoolean("onboarding_completed", completed).apply()
                    result.success(true)
                }
                "startStandbyService" -> {
                    startStandbyBackgroundService()
                    result.success(true)
                }
                "startFocusService" -> {
                    try {
                        val title = call.argument<String>("sessionTitle") ?: "Deep Work"
                        val remainingSecs = call.argument<Int>("remainingSeconds") ?: 1500
                        val blockedList = call.argument<ArrayList<String>>("blockedPackages") ?: arrayListOf()
                        val voiceEnabled = call.argument<Boolean>("voiceAnnouncementsEnabled") ?: true

                        val serviceIntent = Intent(this, FocusForegroundService::class.java).apply {
                            action = FocusForegroundService.ACTION_START
                            putExtra(FocusForegroundService.EXTRA_SESSION_TITLE, title)
                            putExtra(FocusForegroundService.EXTRA_REMAINING_SECONDS, remainingSecs)
                            putStringArrayListExtra(FocusForegroundService.EXTRA_BLOCKED_PACKAGES, blockedList)
                            putExtra(FocusForegroundService.EXTRA_VOICE_ENABLED, voiceEnabled)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            ContextCompat.startForegroundService(this, serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "updateFocusService" -> {
                    try {
                        val remainingSecs = call.argument<Int>("remainingSeconds") ?: 0
                        val isPaused = call.argument<Boolean>("isPaused") ?: false
                        val title = call.argument<String>("sessionTitle")

                        val serviceIntent = Intent(this, FocusForegroundService::class.java).apply {
                            action = FocusForegroundService.ACTION_UPDATE
                            putExtra(FocusForegroundService.EXTRA_REMAINING_SECONDS, remainingSecs)
                            putExtra(FocusForegroundService.EXTRA_IS_PAUSED, isPaused)
                            if (title != null) putExtra(FocusForegroundService.EXTRA_SESSION_TITLE, title)
                            if (call.hasArgument("voiceAnnouncementsEnabled")) {
                                val voiceEnabled = call.argument<Boolean>("voiceAnnouncementsEnabled") ?: true
                                putExtra(FocusForegroundService.EXTRA_VOICE_ENABLED, voiceEnabled)
                            }
                        }
                        startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "stopFocusService" -> {
                    try {
                        val serviceIntent = Intent(this, FocusForegroundService::class.java).apply {
                            action = FocusForegroundService.ACTION_STOP
                        }
                        startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "updateWidget" -> {
                    try {
                        val title = call.argument<String>("sessionTitle") ?: "Daily Focus"
                        val seconds = call.argument<Int>("remainingSeconds") ?: 0
                        val isPaused = call.argument<Boolean>("isPaused") ?: false

                        val appWidgetManager = AppWidgetManager.getInstance(this)
                        val widgetComponent = ComponentName(this, EkagraAppWidgetProvider::class.java)
                        val widgetIds = appWidgetManager.getAppWidgetIds(widgetComponent)

                        if (widgetIds.isNotEmpty()) {
                            val updateIntent = Intent(this, EkagraAppWidgetProvider::class.java).apply {
                                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
                                putExtra(EkagraAppWidgetProvider.EXTRA_TITLE, title)
                                putExtra(EkagraAppWidgetProvider.EXTRA_SECONDS, seconds)
                                putExtra(EkagraAppWidgetProvider.EXTRA_PAUSED, isPaused)
                            }
                            sendBroadcast(updateIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WIDGET_ERROR", e.message, null)
                    }
                }
                "pinWidget" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val appWidgetManager = AppWidgetManager.getInstance(this)
                            val myProvider = ComponentName(this, EkagraAppWidgetProvider::class.java)
                            if (appWidgetManager.isRequestPinAppWidgetSupported) {
                                appWidgetManager.requestPinAppWidget(myProvider, null, null)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("PIN_ERROR", e.message, null)
                    }
                }
                "triggerMiddayDigestNotification" -> {
                    try {
                        val serviceIntent = Intent(this, FocusForegroundService::class.java).apply {
                            action = FocusForegroundService.ACTION_TRIGGER_DIGEST
                        }
                        startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DIGEST_ERROR", e.message, null)
                    }
                }
                "getPendingDigestAction" -> {
                    val wasPending = pendingOpenDigest
                    pendingOpenDigest = false
                    result.success(wasPending)
                }
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    try {
                        if (isTtsReady && textToSpeech != null) {
                            textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "EkagraActivityVoice")
                        }
                    } catch (_: Exception) {}
                    result.success(true)
                }
                "playAlertTone" -> {
                    try {
                        toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP2, 180)
                    } catch (_: Exception) {}
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isUsageAccessGranted(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }
}
