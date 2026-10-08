package com.ekagra.app.ekagra

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class AppUsageDbHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        const val DATABASE_NAME = "ekagra_usage.db"
        const val DATABASE_VERSION = 1

        const val TABLE_USAGE = "app_usage"
        const val COL_PACKAGE = "package_name"
        const val COL_NAME = "app_name"
        const val COL_DATE = "date"
        const val COL_SECONDS = "total_seconds"
        const val COL_BLOCKED_COUNT = "blocked_attempts"
        const val COL_LAST_ACTIVE = "last_active_time"
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createQuery = """
            CREATE TABLE IF NOT EXISTS $TABLE_USAGE (
                $COL_PACKAGE TEXT,
                $COL_NAME TEXT,
                $COL_DATE TEXT,
                $COL_SECONDS INTEGER DEFAULT 0,
                $COL_BLOCKED_COUNT INTEGER DEFAULT 0,
                $COL_LAST_ACTIVE INTEGER DEFAULT 0,
                PRIMARY KEY ($COL_PACKAGE, $COL_DATE)
            )
        """.trimIndent()
        db.execSQL(createQuery)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_USAGE")
        onCreate(db)
    }

    private fun getTodayDateString(): String {
        return SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
    }

    fun recordAppUsage(packageName: String, appName: String, addSeconds: Long) {
        val db = writableDatabase
        val today = getTodayDateString()
        val now = System.currentTimeMillis()

        val cursor = db.rawQuery(
            "SELECT $COL_SECONDS FROM $TABLE_USAGE WHERE $COL_PACKAGE = ? AND $COL_DATE = ?",
            arrayOf(packageName, today)
        )

        if (cursor.moveToFirst()) {
            val existing = cursor.getLong(0)
            cursor.close()
            val cv = ContentValues().apply {
                put(COL_SECONDS, existing + addSeconds)
                put(COL_LAST_ACTIVE, now)
                if (appName.isNotEmpty()) put(COL_NAME, appName)
            }
            db.update(TABLE_USAGE, cv, "$COL_PACKAGE = ? AND $COL_DATE = ?", arrayOf(packageName, today))
        } else {
            cursor.close()
            val cv = ContentValues().apply {
                put(COL_PACKAGE, packageName)
                put(COL_NAME, appName)
                put(COL_DATE, today)
                put(COL_SECONDS, addSeconds)
                put(COL_BLOCKED_COUNT, 0)
                put(COL_LAST_ACTIVE, now)
            }
            db.insertWithOnConflict(TABLE_USAGE, null, cv, SQLiteDatabase.CONFLICT_REPLACE)
        }
    }

    fun recordBlockedAttempt(packageName: String, appName: String) {
        val db = writableDatabase
        val today = getTodayDateString()
        val now = System.currentTimeMillis()

        val cursor = db.rawQuery(
            "SELECT $COL_BLOCKED_COUNT FROM $TABLE_USAGE WHERE $COL_PACKAGE = ? AND $COL_DATE = ?",
            arrayOf(packageName, today)
        )

        if (cursor.moveToFirst()) {
            val currentCount = cursor.getInt(0)
            cursor.close()
            val cv = ContentValues().apply {
                put(COL_BLOCKED_COUNT, currentCount + 1)
                put(COL_LAST_ACTIVE, now)
            }
            db.update(TABLE_USAGE, cv, "$COL_PACKAGE = ? AND $COL_DATE = ?", arrayOf(packageName, today))
        } else {
            cursor.close()
            val cv = ContentValues().apply {
                put(COL_PACKAGE, packageName)
                put(COL_NAME, appName)
                put(COL_DATE, today)
                put(COL_SECONDS, 0)
                put(COL_BLOCKED_COUNT, 1)
                put(COL_LAST_ACTIVE, now)
            }
            db.insertWithOnConflict(TABLE_USAGE, null, cv, SQLiteDatabase.CONFLICT_REPLACE)
        }
    }

    fun syncFromUsageStatsManager(context: Context) {
        try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return
            val pm = context.packageManager

            val cal = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val startOfDay = cal.timeInMillis
            val endOfDay = System.currentTimeMillis()

            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startOfDay,
                endOfDay
            )

            if (stats.isNullOrEmpty()) return

            val db = writableDatabase
            val today = getTodayDateString()

            for (stat in stats) {
                val totalTimeInForeground = stat.totalTimeInForeground // milliseconds
                if (totalTimeInForeground > 5000) { // at least 5 seconds
                    val seconds = totalTimeInForeground / 1000
                    var appName = stat.packageName
                    try {
                        val appInfo = pm.getApplicationInfo(stat.packageName, 0)
                        appName = pm.getApplicationLabel(appInfo).toString()
                    } catch (_: Exception) {}

                    val cv = ContentValues().apply {
                        put(COL_PACKAGE, stat.packageName)
                        put(COL_NAME, appName)
                        put(COL_DATE, today)
                        put(COL_SECONDS, seconds)
                        put(COL_LAST_ACTIVE, stat.lastTimeUsed)
                    }
                    db.insertWithOnConflict(TABLE_USAGE, null, cv, SQLiteDatabase.CONFLICT_REPLACE)
                }
            }
        } catch (_: Exception) {}
    }

    fun getDailyUsage(): List<Map<String, Any>> {
        val db = readableDatabase
        val today = getTodayDateString()
        val list = mutableListOf<Map<String, Any>>()

        val cursor = db.rawQuery(
            "SELECT $COL_PACKAGE, $COL_NAME, $COL_SECONDS, $COL_BLOCKED_COUNT, $COL_LAST_ACTIVE FROM $TABLE_USAGE WHERE $COL_DATE = ? ORDER BY $COL_SECONDS DESC",
            arrayOf(today)
        )

        while (cursor.moveToNext()) {
            val pkg = cursor.getString(0)
            val name = cursor.getString(1)
            val secs = cursor.getLong(2)
            val blocked = cursor.getInt(3)
            val lastActive = cursor.getLong(4)

            list.add(
                mapOf(
                    "packageName" to pkg,
                    "appName" to name,
                    "totalSeconds" to secs,
                    "totalMinutes" to (secs / 60),
                    "blockedAttempts" to blocked,
                    "lastActive" to lastActive
                )
            )
        }
        cursor.close()
        return list
    }
}
