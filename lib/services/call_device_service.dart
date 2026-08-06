import 'package:flutter/services.dart';

class CallDeviceService {
  static const MethodChannel _channel =
      MethodChannel('com.nearmeu.nearmeu/call_device');

  Future<void> enterCallMode() async {
    await _channel.invokeMethod<void>('enterCallMode');
  }

  Future<void> leaveCallMode() async {
    await _channel.invokeMethod<void>('leaveCallMode');
  }

  Future<void> setSpeaker(bool enabled) async {
    await _channel.invokeMethod<void>('setSpeaker', <String, dynamic>{
      'enabled': enabled,
    });
  }

  Future<bool> setBluetooth(bool enabled) async {
    return await _channel.invokeMethod<bool>('setBluetooth', <String, dynamic>{
          'enabled': enabled,
        }) ??
        false;
  }

  Future<void> setProximityEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setProximityEnabled', <String, dynamic>{
      'enabled': enabled,
    });
  }

  Future<bool> bluetoothAvailable() async {
    return await _channel.invokeMethod<bool>('isBluetoothAvailable') ?? false;
  }

  Future<bool> bluetoothSelected() async {
    return await _channel.invokeMethod<bool>('isBluetoothSelected') ?? false;
  }

  Future<void> openCallNotificationSettings() async {
    await _channel.invokeMethod<void>('openCallNotificationSettings');
  }
}
