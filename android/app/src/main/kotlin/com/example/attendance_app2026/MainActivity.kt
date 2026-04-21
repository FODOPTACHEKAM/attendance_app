package com.example.attendance_app2026

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "hotspot_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startHotspot" -> {
                    val ssid = call.argument<String>("ssid")
                    val password = call.argument<String>("password") ?: "12345678"
                    val intent = Intent(this, HotspotService::class.java).apply {
                        action = HotspotService.ACTION_START
                        putExtra("ssid", ssid)
                        putExtra("password", password)
                    }
                    startService(intent)
                    result.success("Hotspot started: http://192.168.43.1:${HotspotService.PORT}")
                }
                "stopHotspot" -> {
                    val intent = Intent(this, HotspotService::class.java).apply {
                        action = HotspotService.ACTION_STOP
                    }
                    stopService(intent)
                    result.success("Hotspot stopped")
                }
                "getStatus" -> {
                    // Check if service running - simplified
                    result.success("unknown")
                }
                "getLocalServerUrl" -> {
                    result.success("http://192.168.43.1:${HotspotService.PORT}")
                }
                "getPendingRegistrations" -> {
                    result.notImplemented()
                }
                else -> result.notImplemented()
            }
        }
    }
}
