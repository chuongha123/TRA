import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../constants/app_constants.dart';

@pragma('vm:entry-point')
void backgroundScheduleCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (task == BackgroundScheduleService.scheduleTaskName) {
      final scheduleId = inputData?['scheduleId']?.toString();
      if (scheduleId != null && scheduleId.isNotEmpty) {
        await BackgroundScheduleService.runScheduleTask(scheduleId);
      }
      return true;
    }

    if (task == BackgroundScheduleService.pumpOffTaskName) {
      await BackgroundScheduleService.runPumpOffTask();
      return true;
    }

    return true;
  });
}

class BackgroundScheduleService {
  static const String scheduleTaskName = 'irrigation_schedule_task';
  static const String pumpOffTaskName = 'irrigation_pump_off_task';
  static const String _scheduleUniquePrefix = 'irrigation_schedule_';
  static const String _pumpOffUniquePrefix = 'irrigation_pump_off_';
  static const String _registeredScheduleIdsKey =
      'background_registered_schedule_ids';
  static const String _schedulesStorageKey = 'irrigation_schedules';
  static const String _deviceId = 'esp32_garden_01';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!Platform.isAndroid) {
      return;
    }

    if (!_initialized) {
      await Workmanager().initialize(
        backgroundScheduleCallbackDispatcher,
        isInDebugMode: false,
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

  static Future<void> syncSchedulesFromStorage({
    bool cancelPumpOffTasks = true,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_schedulesStorageKey);
    if (raw == null || raw.isEmpty) {
      await _syncSchedulesInternal(
        const <Map<String, dynamic>>[],
        cancelPumpOffTasks: cancelPumpOffTasks,
      );
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final schedules = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await _syncSchedulesInternal(
        schedules,
        cancelPumpOffTasks: cancelPumpOffTasks,
      );
    } catch (_) {
      await _syncSchedulesInternal(
        const <Map<String, dynamic>>[],
        cancelPumpOffTasks: cancelPumpOffTasks,
      );
    }
  }

  static Future<void> _syncSchedulesInternal(
    List<Map<String, dynamic>> schedules,
    {
    bool cancelPumpOffTasks = true,
    }
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final oldIds = (prefs.getStringList(_registeredScheduleIdsKey) ?? <String>[])
        .where((e) => e.isNotEmpty)
        .toSet();

    final nextIds = schedules
        .map((e) => e['id']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet();

    for (final removedId in oldIds.difference(nextIds)) {
      await Workmanager().cancelByUniqueName('$_scheduleUniquePrefix$removedId');
      await Workmanager().cancelByUniqueName('$_pumpOffUniquePrefix$removedId');
    }

    for (final schedule in schedules) {
      final id = schedule['id']?.toString() ?? '';
      if (id.isEmpty) {
        continue;
      }

      await Workmanager().cancelByUniqueName('$_scheduleUniquePrefix$id');
      if (cancelPumpOffTasks) {
        await Workmanager().cancelByUniqueName('$_pumpOffUniquePrefix$id');
      }

      if (schedule['isEnabled'] != true) {
        continue;
      }

      final nextRun = _computeNextOccurrence(schedule, DateTime.now());
      if (nextRun == null) {
        continue;
      }

      final delay = nextRun.difference(DateTime.now());
      await Workmanager().registerOneOffTask(
        '$_scheduleUniquePrefix$id',
        scheduleTaskName,
        initialDelay: delay.isNegative ? Duration.zero : delay,
        inputData: <String, dynamic>{'scheduleId': id},
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    }

    await prefs.setStringList(_registeredScheduleIdsKey, nextIds.toList());
  }

  static DateTime? _computeNextOccurrence(
    Map<String, dynamic> schedule,
    DateTime now,
  ) {
    final rawDays = (schedule['days'] as List?) ?? <dynamic>[];
    final days = List<bool>.generate(7, (index) {
      if (index >= rawDays.length) {
        return false;
      }
      return rawDays[index] == true;
    });

    final hour = (schedule['hour'] as num?)?.toInt() ?? 0;
    final minute = (schedule['minute'] as num?)?.toInt() ?? 0;

    for (int offset = 0; offset <= 7; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      final weekdayIndex = (day.weekday + 6) % 7; // Monday=0 ... Sunday=6
      if (!days[weekdayIndex]) {
        continue;
      }

      final candidate = DateTime(day.year, day.month, day.day, hour, minute);
      if (candidate.isAfter(now.add(const Duration(seconds: 5)))) {
        return candidate;
      }
    }

    return null;
  }

  static Future<void> runScheduleTask(String scheduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_schedulesStorageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    Map<String, dynamic>? matched;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final item in decoded.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        if ((map['id']?.toString() ?? '') == scheduleId) {
          matched = map;
          break;
        }
      }
    } catch (_) {
      return;
    }

    if (matched == null || matched['isEnabled'] != true) {
      await syncSchedulesFromStorage();
      return;
    }

    // Keep behavior consistent with foreground scheduler: if pump is already on,
    // skip this schedule run to avoid overlapping watering windows.
    if (await _isPumpCurrentlyOn()) {
      await syncSchedulesFromStorage();
      return;
    }

    final didTurnOn = await _sendPumpToggle(true, triggeredBy: 'schedule');
    if (!didTurnOn) {
      await syncSchedulesFromStorage();
      return;
    }

    final durationMinutes = (matched['durationMinutes'] as num?)?.toInt() ?? 1;
    final offDelay = Duration(minutes: durationMinutes.clamp(1, 240));

    await Workmanager().registerOneOffTask(
      '$_pumpOffUniquePrefix$scheduleId',
      pumpOffTaskName,
      initialDelay: offDelay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    await syncSchedulesFromStorage(cancelPumpOffTasks: false);
  }

  static Future<void> runPumpOffTask() async {
    await _sendPumpToggle(false, triggeredBy: 'schedule');
  }

  static Future<bool> _sendPumpToggle(
    bool isOn, {
    required String triggeredBy,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/pump/toggle');
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'deviceId': _deviceId,
          'isOn': isOn,
          'triggeredBy': triggeredBy,
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      // Keep background task resilient; next schedule run will retry naturally.
      return false;
    }
  }

  static Future<bool> _isPumpCurrentlyOn() async {
    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/pump/latest?deviceId=$_deviceId',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      return decoded['isOn'] == true;
    } catch (_) {
      return false;
    }
  }
}
