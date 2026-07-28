package com.nearmeu.nearmeu

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val screenSecurityChannel = "com.nearmeu.nearmeu/screen_security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Debug/testing builds must allow screenshots for issue reporting.
        // Production release builds remain secure by default.
        setScreenCaptureBlocked(!BuildConfig.DEBUG)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            screenSecurityChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setScreenCaptureBlocked" -> {
                    val requestedBlocked = call.argument<Boolean>("blocked") ?: true
                    val blocked = if (BuildConfig.DEBUG) false else requestedBlocked
                    runOnUiThread { setScreenCaptureBlocked(blocked) }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setScreenCaptureBlocked(blocked: Boolean) {
        if (blocked) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
