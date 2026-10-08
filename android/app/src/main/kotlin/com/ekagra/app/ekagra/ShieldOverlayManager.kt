package com.ekagra.app.ekagra

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class ShieldOverlayManager(private val context: Context) {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isShowing = false
    private var currentBlockedPkg: String = ""

    private var countdownTv: TextView? = null
    private var remainingSeconds: Int = 0
    private var isSnoozed = false
    private var snoozeUntil: Long = 0

    private val handler = Handler(Looper.getMainLooper())

    fun isCurrentlyShowing(): Boolean = isShowing
    fun getBlockedPackage(): String = currentBlockedPkg

    fun isSnoozedActive(): Boolean {
        if (isSnoozed && System.currentTimeMillis() < snoozeUntil) {
            return true
        }
        isSnoozed = false
        return false
    }

    fun showOverlay(appName: String, packageName: String, sessionTitle: String, seconds: Int) {
        if (isSnoozedActive()) return
        if (isShowing && currentBlockedPkg == packageName) {
            remainingSeconds = seconds
            updateCountdownText()
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
            // Cannot draw overlay without permission
            return
        }

        handler.post {
            try {
                if (isShowing && overlayView != null) {
                    try {
                        windowManager?.removeView(overlayView)
                    } catch (_: Exception) {}
                    overlayView = null
                    isShowing = false
                }

                currentBlockedPkg = packageName
                remainingSeconds = seconds

                windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

                val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    layoutType,
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                            WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.CENTER
                }

                overlayView = createOverlayView(appName, sessionTitle)
                windowManager?.addView(overlayView, params)
                isShowing = true
            } catch (e: Exception) {
                isShowing = false
            }
        }
    }

    fun updateSeconds(seconds: Int) {
        remainingSeconds = seconds
        handler.post {
            updateCountdownText()
        }
    }

    fun hideOverlay() {
        if (!isShowing || overlayView == null) return
        handler.post {
            try {
                if (overlayView != null) {
                    windowManager?.removeView(overlayView)
                }
            } catch (_: Exception) {}
            overlayView = null
            isShowing = false
            currentBlockedPkg = ""
        }
    }

    private fun updateCountdownText() {
        val mins = remainingSeconds / 60
        val secs = remainingSeconds % 60
        countdownTv?.text = String.format("%02d:%02d\nREMAINING IN FOCUS SESSION", mins, secs)
    }

    private fun createOverlayView(appName: String, sessionTitle: String): View {
        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#FA0B0D10")) // deep dark with 98% opacity
            setPadding(56, 80, 56, 80)
            isClickable = true
            isFocusable = true
        }

        // Circular Shield Icon
        val shieldBadge = LinearLayout(context).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#1E2435"))
                setStroke(3, Color.parseColor("#7C8CFF"))
            }
            background = bg
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(160, 160).apply {
                bottomMargin = 36
            }
        }
        val iconTv = TextView(context).apply {
            text = "🛡️"
            textSize = 40f
            gravity = Gravity.CENTER
        }
        shieldBadge.addView(iconTv)
        root.addView(shieldBadge)

        // Title
        val titleTv = TextView(context).apply {
            text = "Focus Shield Engaged"
            textSize = 24f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 14
            }
        }
        root.addView(titleTv)

        // Restricted App Chip
        val chip = LinearLayout(context).apply {
            val chipBg = GradientDrawable().apply {
                cornerRadius = 32f
                setColor(Color.parseColor("#33FF4D4D"))
                setStroke(1, Color.parseColor("#80FF4D4D"))
            }
            background = chipBg
            setPadding(28, 10, 28, 10)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 32
            }
        }
        val chipText = TextView(context).apply {
            text = "▶ $appName is currently restricted"
            textSize = 13f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.parseColor("#FF6B6B"))
        }
        chip.addView(chipText)
        root.addView(chip)

        // Countdown Card
        val timerCard = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            val cardBg = GradientDrawable().apply {
                cornerRadius = 28f
                setColor(Color.parseColor("#13161B"))
                setStroke(1, Color.parseColor("#252A36"))
            }
            background = cardBg
            setPadding(40, 28, 40, 28)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 36
            }
        }

        countdownTv = TextView(context).apply {
            textSize = 28f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setLineSpacing(4f, 1f)
        }
        updateCountdownText()
        timerCard.addView(countdownTv)
        root.addView(timerCard)

        // Quote
        val quoteTv = TextView(context).apply {
            text = "You are in deep flow. Protect your attention from quick impulses."
            textSize = 13f
            setTextColor(Color.parseColor("#9BA1B0"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 48
            }
        }
        root.addView(quoteTv)

        // Primary Action: Return to Focus Session
        val returnBtn = Button(context).apply {
            text = "← Return to Focus Session"
            textSize = 15f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.WHITE)
            val btnBg = GradientDrawable().apply {
                cornerRadius = 24f
                setColor(Color.parseColor("#7C8CFF"))
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                130
            ).apply {
                bottomMargin = 20
            }
            setOnClickListener {
                hideOverlay()
                // Launch MainActivity
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                context.startActivity(intent)
            }
        }
        root.addView(returnBtn)

        // Secondary Action: 60s emergency access
        val snoozeBtn = TextView(context).apply {
            text = "Need 60s emergency access?"
            textSize = 12f
            setTextColor(Color.parseColor("#6A7182"))
            gravity = Gravity.CENTER
            setPadding(16, 16, 16, 16)
            setOnClickListener {
                isSnoozed = true
                snoozeUntil = System.currentTimeMillis() + 60000L
                hideOverlay()
            }
        }
        root.addView(snoozeBtn)

        return root
    }
}
