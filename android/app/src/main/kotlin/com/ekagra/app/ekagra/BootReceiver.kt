package com.ekagra.app.ekagra

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON") {
            try {
                val serviceIntent = Intent(context, FocusForegroundService::class.java).apply {
                    this.action = FocusForegroundService.ACTION_START_STANDBY
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    ContextCompat.startForegroundService(context, serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (_: Exception) {}
        } else if (action == "com.ekagra.app.action.TEST_START_FOCUS") {
            try {
                val serviceIntent = Intent(context, FocusForegroundService::class.java).apply {
                    this.action = FocusForegroundService.ACTION_START
                    putExtra(FocusForegroundService.EXTRA_SESSION_TITLE, intent.getStringExtra(FocusForegroundService.EXTRA_SESSION_TITLE) ?: "Deep Work")
                    putExtra(FocusForegroundService.EXTRA_REMAINING_SECONDS, intent.getIntExtra(FocusForegroundService.EXTRA_REMAINING_SECONDS, 1500))
                    val pkgs = intent.getStringArrayListExtra(FocusForegroundService.EXTRA_BLOCKED_PACKAGES) ?: arrayListOf("com.google.android.youtube", "com.instagram.android")
                    putStringArrayListExtra(FocusForegroundService.EXTRA_BLOCKED_PACKAGES, pkgs)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    ContextCompat.startForegroundService(context, serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (_: Exception) {}
        } else if (action == "com.ekagra.app.action.TEST_STOP_FOCUS") {
            try {
                val serviceIntent = Intent(context, FocusForegroundService::class.java).apply {
                    this.action = FocusForegroundService.ACTION_STOP
                }
                context.startService(serviceIntent)
            } catch (_: Exception) {}
        }
    }
}
