package com.example.wishpr_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.wishpr_app/sms",
        ).setMethodCallHandler { call, result ->
            if (call.method != "sendDirectSms") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val phone = call.argument<String>("phone")
            val body = call.argument<String>("body")
            if (phone.isNullOrBlank() || body.isNullOrBlank()) {
                result.error("invalid_args", "phone and body required", null)
                return@setMethodCallHandler
            }
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                result.error("permission_denied", "SEND_SMS not granted", null)
                return@setMethodCallHandler
            }
            try {
                val sm: SmsManager =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        getSystemService(SmsManager::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        SmsManager.getDefault()
                    }
                if (body.length > 160) {
                    val parts = sm.divideMessage(body)
                    sm.sendMultipartTextMessage(phone, null, parts, null, null)
                } else {
                    sm.sendTextMessage(phone, null, body, null, null)
                }
                result.success(true)
            } catch (e: Exception) {
                result.error("send_failed", e.message, null)
            }
        }
    }
}
