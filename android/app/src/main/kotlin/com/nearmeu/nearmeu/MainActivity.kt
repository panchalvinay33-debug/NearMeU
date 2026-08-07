package com.nearmeu.nearmeu

import android.content.Context
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val profileChannelName = "com.nearmeu.nearmeu/profile_sharing"
    private val callDeviceChannelName = "com.nearmeu.nearmeu/call_device"
    private val callNotificationChannelId = "nearmeu_calls"
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
                            setSpeakerInternal(false)
                            result.success(null)
                        }
                        "leaveCallMode" -> {
                            releaseProximityWakeLock()
                            routeBluetooth(false)
                            setSpeakerInternal(false)
                            audioManager().mode = AudioManager.MODE_NORMAL
                            result.success(null)
                        }
                        "setSpeaker" -> {
                            val enabled = call.argument<Boolean>("enabled") == true
                            if (enabled) routeBluetooth(false)
                            setSpeakerInternal(enabled)
                            if (enabled) releaseProximityWakeLock()
                            result.success(null)
                        }
                        "setBluetooth" -> {
                            val enabled = call.argument<Boolean>("enabled") == true
                            if (enabled) {
                                setSpeakerInternal(false)
                                releaseProximityWakeLock()
                            }
                            result.success(routeBluetooth(enabled))
                        }
                        "setProximityEnabled" -> {
                            val enabled = call.argument<Boolean>("enabled") == true
                            if (enabled && !isSpeakerEnabled() && !isBluetoothSelected()) {
                                acquireProximityWakeLock()
                            } else {
                                releaseProximityWakeLock()
                            }
                            result.success(null)
                        }
                        "isBluetoothAvailable" -> result.success(isBluetoothAvailable())
                        "isBluetoothSelected" -> result.success(isBluetoothSelected())
                        "openCallNotificationSettings" -> {
                            openCallNotificationSettings()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Throwable) {
                    result.error("call-device-error", error.message, null)
                }
            }
    }

    private fun audioManager(): AudioManager =
        getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private fun openCallNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                putExtra(Settings.EXTRA_CHANNEL_ID, callNotificationChannelId)
            }
        } else {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra("app_package", packageName)
                putExtra("app_uid", applicationInfo.uid)
            }
        }
        startActivity(intent)
    }

    @Suppress("DEPRECATION")
    private fun setSpeakerInternal(enabled: Boolean) {
        val manager = audioManager()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (enabled) {
                val speaker = manager.availableCommunicationDevices.firstOrNull {
                    it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
                }
                if (speaker != null) manager.setCommunicationDevice(speaker)
            } else if (manager.communicationDevice?.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER) {
                manager.clearCommunicationDevice()
            }
        } else {
            manager.isSpeakerphoneOn = enabled
        }
    }

    @Suppress("DEPRECATION")
    private fun isSpeakerEnabled(): Boolean {
        val manager = audioManager()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            manager.communicationDevice?.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
        } else {
            manager.isSpeakerphoneOn
        }
    }

    @Suppress("DEPRECATION")
    private fun routeBluetooth(enabled: Boolean): Boolean {
        val manager = audioManager()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!enabled) {
                val selected = manager.communicationDevice
                if (selected != null && isBluetoothType(selected.type)) {
                    manager.clearCommunicationDevice()
                }
                return true
            }
            val bluetooth = manager.availableCommunicationDevices.firstOrNull {
                isBluetoothType(it.type)
            } ?: return false
            return manager.setCommunicationDevice(bluetooth)
        }

        if (!manager.isBluetoothScoAvailableOffCall) return !enabled
        return if (enabled) {
            manager.startBluetoothSco()
            manager.isBluetoothScoOn = true
            true
        } else {
            manager.isBluetoothScoOn = false
            manager.stopBluetoothSco()
            true
        }
    }

    @Suppress("DEPRECATION")
    private fun isBluetoothSelected(): Boolean {
        val manager = audioManager()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val selected = manager.communicationDevice
            selected != null && isBluetoothType(selected.type)
        } else {
            manager.isBluetoothScoOn
        }
    }

    private fun isBluetoothType(type: Int): Boolean {
        return type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
            type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
            (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && type == AudioDeviceInfo.TYPE_BLE_SPEAKER)
    }

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
            manager.availableCommunicationDevices.any { isBluetoothType(it.type) }
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
