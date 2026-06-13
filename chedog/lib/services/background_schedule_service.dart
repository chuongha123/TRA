import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class BackgroundScheduleService {
  static const String _schedulesStorageKey = 'irrigation_schedules';
  static const String _deviceId = 'esp32_garden_01';
  static const MethodChannel _channel =
      MethodChannel('com.example.Tra/background_alarm');
  static const Duration _channelTimeout = Duration(seconds: 5);

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!Platform.isAndroid) {
      return;
    }

    if (!_initialized) {
      await _invokeChannel(
        'initialize',
        <String, dynamic>{
          'apiBaseUrl': AppConstants.apiBaseUrl,
          'deviceId': _deviceId,
        },
      );
      _initialized = true;
    }

    await syncSchedulesFromStorage();
  }

  static Future<void> syncSchedules(
    List<Map<String, dynamic>> schedules,
  ) async {
    if (!Platform.isAndroid) {
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    await _syncSchedulesInternal(schedules);
  }

  static Future<void> syncSchedulesFromStorage() async {
    if (!Platform.isAndroid) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_schedulesStorageKey);
    if (raw == null || raw.isEmpty) {
      await _syncSchedulesInternal(const <Map<String, dynamic>>[]);
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final schedules = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await _syncSchedulesInternal(schedules);
    } catch (_) {
      await _syncSchedulesInternal(const <Map<String, dynamic>>[]);
    }
  }

  static Future<void> _syncSchedulesInternal(
    List<Map<String, dynamic>> schedules,
  ) async {
    await _invokeChannel(
      'syncSchedules',
      <String, dynamic>{
        'apiBaseUrl': AppConstants.apiBaseUrl,
        'deviceId': _deviceId,
        'schedules': schedules,
      },
    );
  }

  static Future<void> _invokeChannel(
    String method,
    Map<String, dynamic> arguments,
  ) async {
    try {
      await _channel
          .invokeMethod<void>(method, arguments)
          .timeout(_channelTimeout);
    } on TimeoutException {
      // Avoid blocking UI if the Android alarm channel is slow or stuck.
    } on PlatformException {
      // Native handler missing or rejected the call.
    } catch (_) {
      // Best-effort background sync.
    }
  }
}
