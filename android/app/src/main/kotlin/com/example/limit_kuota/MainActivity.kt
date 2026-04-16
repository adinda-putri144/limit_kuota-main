package com.example.limit_kuota

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "limit_kuota/channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "getTodayUsage" -> {
                        result.success(getTodayTotalUsage())
                    }

                    "getAppUsage" -> {
                        result.success(getAppUsage())
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun getTodayTotalUsage(): Map<String, Long> {
        val statsManager =
            getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

        val endTime = System.currentTimeMillis()
        val startTime = endTime - (24 * 60 * 60 * 1000)

        var wifiBytes = 0L
        var mobileBytes = 0L
        val bucket = NetworkStats.Bucket()

        val wifiStats = statsManager.querySummary(
            ConnectivityManager.TYPE_WIFI, null, startTime, endTime
        )
        while (wifiStats.hasNextBucket()) {
            wifiStats.getNextBucket(bucket)
            wifiBytes += bucket.rxBytes + bucket.txBytes
        }
        wifiStats.close()

        val mobileStats = statsManager.querySummary(
            ConnectivityManager.TYPE_MOBILE, null, startTime, endTime
        )
        while (mobileStats.hasNextBucket()) {
            mobileStats.getNextBucket(bucket)
            mobileBytes += bucket.rxBytes + bucket.txBytes
        }
        mobileStats.close()

        return mapOf("wifi" to wifiBytes, "mobile" to mobileBytes)
    }

    // ⭐ FIX SAMSUNG — PER APLIKASI
    private fun getAppUsage(): List<Map<String, Any>> {
        val statsManager =
            getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val pm = packageManager

        val startTime = System.currentTimeMillis() - (24 * 60 * 60 * 1000)
        val endTime = System.currentTimeMillis()

        val result = mutableListOf<Map<String, Any>>()
        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        for (app in apps) {
            try {
                val uid = app.uid
                var totalBytes = 0L
                val bucket = NetworkStats.Bucket()

                val mobileStats = statsManager.queryDetailsForUid(
                    ConnectivityManager.TYPE_MOBILE, null, startTime, endTime, uid
                )
                while (mobileStats.hasNextBucket()) {
                    mobileStats.getNextBucket(bucket)
                    totalBytes += bucket.rxBytes + bucket.txBytes
                }
                mobileStats.close()

                val wifiStats = statsManager.queryDetailsForUid(
                    ConnectivityManager.TYPE_WIFI, null, startTime, endTime, uid
                )
                while (wifiStats.hasNextBucket()) {
                    wifiStats.getNextBucket(bucket)
                    totalBytes += bucket.rxBytes + bucket.txBytes
                }
                wifiStats.close()

                if (totalBytes > 5 * 1024 * 1024) {
                    val appName = pm.getApplicationLabel(app).toString()
                    result.add(mapOf("appName" to appName, "bytes" to totalBytes))
                }

            } catch (_: Exception) {}
        }

        return result.sortedByDescending { it["bytes"] as Long }.take(10)
    }
}