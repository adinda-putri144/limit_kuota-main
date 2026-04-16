package com.example.limit_kuota

import android.app.usage.NetworkStatsManager
import android.app.usage.NetworkStats
import android.content.Context
import android.net.ConnectivityManager
import android.os.Build
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.M)
class AppUsageService(private val context: Context) {

    fun getAppDataUsage(): List<Map<String, Any>> {
        val result = mutableListOf<Map<String, Any>>()
        val statsManager =
            context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

        val bucket = NetworkStats.Bucket()
        val startTime = System.currentTimeMillis() - (24 * 60 * 60 * 1000)
        val endTime = System.currentTimeMillis()

        val networkStats = statsManager.querySummary(
            ConnectivityManager.TYPE_MOBILE,
            null,
            startTime,
            endTime
        )

        while (networkStats.hasNextBucket()) {
            networkStats.getNextBucket(bucket)
            result.add(
                mapOf(
                    "uid" to bucket.uid,
                    "rx" to bucket.rxBytes,
                    "tx" to bucket.txBytes
                )
            )
        }
        networkStats.close()
        return result
    }
}