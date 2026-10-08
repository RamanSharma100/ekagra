package com.ekagra.app.ekagra

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class BlockOverlayActivity : Activity() {

    companion object {
        const val EXTRA_APP_NAME = "extra_app_name"
        const val EXTRA_PACKAGE_NAME = "extra_package_name"
        const val EXTRA_REMAINING_SECONDS = "extra_remaining_seconds"
        const val EXTRA_SESSION_TITLE = "extra_session_title"
    }

    private var countdownTv: TextView? = null
    private var remainingSeconds: Int = 0
    private val handler = Handler(Looper.getMainLooper())
    private val timerRunnable = object : Runnable {
        override fun run() {
            if (remainingSeconds > 0) {
                remainingSeconds--
                updateCountdownDisplay()
                handler.postDelayed(this, 1000)
            } else {
                finish()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val appName = intent.getStringExtra(EXTRA_APP_NAME) ?: "Protected App"
        val sessionTitle = intent.getStringExtra(EXTRA_SESSION_TITLE) ?: "Deep Focus"
        remainingSeconds = intent.getIntExtra(EXTRA_REMAINING_SECONDS, 1500)

        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0B0D10"))
            setPadding(64, 96, 64, 96)
        }

        // Shield Badge Icon Container
        val iconBadge = LinearLayout(this).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#1A1F2C"))
                setStroke(2, Color.parseColor("#7C8CFF"))
            }
            background = bg
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(160, 160).apply {
                bottomMargin = 48
            }
        }

        val iconTv = TextView(this).apply {
            text = "🛡️"
            textSize = 36f
            gravity = Gravity.CENTER
        }
        iconBadge.addView(iconTv)
        rootLayout.addView(iconBadge)

        // Title
        val titleTv = TextView(this).apply {
            text = "Focus Shield Active"
            textSize = 24f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 16
            }
        }
        rootLayout.addView(titleTv)

        // Blocked app explanation
        val subtitleTv = TextView(this).apply {
            text = "$appName is restricted during your focus sprint"
            textSize = 15f
            setTextColor(Color.parseColor("#9BA1B0"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 36
            }
        }
        rootLayout.addView(subtitleTv)

        // Countdown Timer Box
        val countdownBox = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            val boxBg = GradientDrawable().apply {
                cornerRadius = 24f
                setColor(Color.parseColor("#13161B"))
                setStroke(1, Color.parseColor("#252A36"))
            }
            background = boxBg
            setPadding(48, 28, 48, 28)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 48
            }
        }

        val countdownLabel = TextView(this).apply {
            text = sessionTitle.uppercase()
            textSize = 11f
            letterSpacing = 0.15f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.parseColor("#7C8CFF"))
            gravity = Gravity.CENTER
        }
        countdownBox.addView(countdownLabel)

        countdownTv = TextView(this).apply {
            textSize = 32f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 8, 0, 0)
        }
        updateCountdownDisplay()
        countdownBox.addView(countdownTv)

        rootLayout.addView(countdownBox)

        // Cognitive Quote
        val quoteTv = TextView(this).apply {
            text = "“Every distraction avoided strengthens your concentration muscle.”"
            textSize = 13f
            setTextColor(Color.parseColor("#6A7182"))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 56
            }
        }
        rootLayout.addView(quoteTv)

        // Action Button: Return to Ekagra
        val returnButton = Button(this).apply {
            text = "Return to Focus"
            textSize = 16f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.WHITE)
            val btnBg = GradientDrawable().apply {
                cornerRadius = 28f
                setColor(Color.parseColor("#7C8CFF"))
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                140
            ).apply {
                bottomMargin = 24
            }
            setOnClickListener {
                returnToEkagra()
            }
        }
        rootLayout.addView(returnButton)

        // Secondary Action: Go to Home
        val homeButton = Button(this).apply {
            text = "Go to Home Screen"
            textSize = 14f
            setTextColor(Color.parseColor("#9BA1B0"))
            val homeBg = GradientDrawable().apply {
                cornerRadius = 28f
                setColor(Color.TRANSPARENT)
                setStroke(1, Color.parseColor("#252A36"))
            }
            background = homeBg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                120
            )
            setOnClickListener {
                goToHomeScreen()
            }
        }
        rootLayout.addView(homeButton)

        setContentView(rootLayout)
        handler.post(timerRunnable)
    }

    private fun updateCountdownDisplay() {
        val mins = remainingSeconds / 60
        val secs = remainingSeconds % 60
        countdownTv?.text = String.format("%02d:%02d remaining", mins, secs)
    }

    private fun returnToEkagra() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }
        startActivity(intent)
        finish()
    }

    private fun goToHomeScreen() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    override fun onBackPressed() {
        // Prevent bypassing straight back into the restricted application
        goToHomeScreen()
    }

    override fun onDestroy() {
        handler.removeCallbacks(timerRunnable)
        super.onDestroy()
    }
}
