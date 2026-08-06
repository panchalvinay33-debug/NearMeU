package com.nearmeu.nearmeu

import android.content.Context
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val profileChannelName = "com.nearmeu.nearmeu/profile_sharing"
    private val callDeviceChannelName = "com.nearmeu.nearmeu/call_device"
    private var profileChannel: MethodChannel? = null
    private var initialLink: String? = null
    private var proximityWakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialLink = intent?.dataString
        profileChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, profileChannelName).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> {
                        val link = initialLink
                        initialLink = null
                        result.success(link)
                    }
                    "shareText" -> {
                        val text = call.argument<String>("text")?.trim().orEmpty()
                        if (text.isEmpty()) {
                            result.error("invalid-argument", "Share text is required.", null)
                            return@setMethodCallHandler
                        }
                        val chooser = Intent.createChooser(
                            Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, text)
                            },
                            "Share NearMeU profile",
                        )
                        startActivity(chooser)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, callDeviceChannelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "enterCallMode" -> {
                            audioManager().mode = AudioManager.MODE_IN_COMMUNICATION
                            audioManager().isSpeakerphoneOn = false
                            result.success(null)
                        }
                        "leaveCallMode" -> {
                            releaseProximityWakeLock()
                            audioManager().isSpeakerphoneOn = false
                            audioManager().mode = AudioManager.MODE_NORMAL
                            result.success(null)
                        }
                        "setSpeaker" -> {
                            val enabled = call.argument<Boolean>("enabled") == true
                            audioManager().isSpeakerphoneOn = enabled
                            if (enabled) releaseProximityWakeLock()
                            result.success(null)
                        }
                        "setProximityEnabled" -> {
                            val enabled = call.argument<Boolean>("enabled") == true
                            if (enabled && !audioManager().isSpeakerphoneOn) {
                                acquireProximityWakeLock()
                            } else {
                                releaseProximityWakeLock()
                            }
                            result.success(null)
                        }
                        "isBluetoothAvailable" -> result.success(isBluetoothAvailable())
                        else -> result.notImplemented()
                    }
                } catch (error: Throwable) {
                    result.error("call-device-error", error.message, null)
                }
            }
    }

    private fun audioManager(): AudioManager =
        getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private fun acquireProximityWakeLock() {
        if (proximityWakeLock?.isHeld == true) return
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!powerManager.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) return
        proximityWakeLock = powerManager.newWakeLock(
            PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
            "NearMeU:AudioCallProximity",
        ).apply { acquire() }
    }

    private fun releaseProximityWakeLock() {
        val wakeLock = proximityWakeLock
        proximityWakeLock = null
        if (wakeLock?.isHeld == true) wakeLock.release()
    }

    @Suppress("DEPRECATION")
    private fun isBluetoothAvailable(): Boolean {
        val manager = audioManager()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            manager.availableCommunicationDevices.any {
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                    it.type == AudioDeviceInfo.TYPE_BLE_HEADSET
            }
        } else {
            manager.isBluetoothScoAvailableOffCall
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val link = intent.dataString ?: return
        profileChannel?.invokeMethod("onDeepLink", link)
    }

    override fun onDestroy() {
        releaseProximityWakeLock()
        super.onDestroy()
    }
}
