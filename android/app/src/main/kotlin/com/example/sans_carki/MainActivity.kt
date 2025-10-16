package com.sanscarki.app

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "performance_detector"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSystemInfo" -> {
                    val systemInfo = getSystemInfo()
                    result.success(systemInfo)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getSystemInfo(): Map<String, Any> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        
        val ramMB = (memoryInfo.totalMem / (1024 * 1024)).toInt()
        val cpuCores = Runtime.getRuntime().availableProcessors()
        val cpuArch = Build.SUPPORTED_ABIS[0] ?: "unknown"
        
        return mapOf(
            "ramMB" to ramMB,
            "cpuCores" to cpuCores,
            "cpuArch" to cpuArch
        )
    }
}
