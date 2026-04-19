import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/background_schedule_service.dart';
import 'sensor_provider.dart';

/// Schedule Item - Lịch tưới nước
class IrrigationSchedule {
  final String id;
  final String name;
  final TimeOfDay time;
  final List<bool> days; // [T2, T3, T4, T5, T6, T7, CN]
  final int durationMinutes;
  final String zone;
  bool isEnabled;

  IrrigationSchedule({
    required this.id,
    required this.name,
    required this.time,
    required this.days,
    required this.durationMinutes,
    required this.zone,
    this.isEnabled = true,
  });

  String get daysLabel {
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final active = <String>[];
    for (int i = 0; i < 7; i++) {
      if (days[i]) active.add(labels[i]);
    }
    if (active.length == 7) return 'Hàng ngày';
    if (active.length == 5 &&
        !days[5] &&
        !days[6]) {
      return 'Ngày trong tuần';
    }
    if (active.length == 2 && days[5] && days[6]) return 'Cuối tuần';
    return active.join(', ');
  }

  String get timeLabel {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  IrrigationSchedule copyWith({
    String? name,
    TimeOfDay? time,
    List<bool>? days,
    int? durationMinutes,
    String? zone,
    bool? isEnabled,
  }) {
    return IrrigationSchedule(
      id: id,
      name: name ?? this.name,
      time: time ?? this.time,
      days: days ?? List.from(this.days),
      durationMinutes: durationMinutes ?? this.durationMinutes,
      zone: zone ?? this.zone,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hour': time.hour,
      'minute': time.minute,
      'days': days,
      'durationMinutes': durationMinutes,
      'zone': zone,
      'isEnabled': isEnabled,
    };
  }

  factory IrrigationSchedule.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List?) ?? <dynamic>[];
    final parsedDays = List<bool>.generate(7, (index) {
      if (index >= rawDays.length) {
        return false;
      }
      final value = rawDays[index];
      if (value is bool) return value;
      return value == true;
    });

    return IrrigationSchedule(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      time: TimeOfDay(
        hour: (json['hour'] as num?)?.toInt() ?? 0,
        minute: (json['minute'] as num?)?.toInt() ?? 0,
      ),
      days: parsedDays,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 1,
      zone: (json['zone'] ?? '').toString(),
      isEnabled: json['isEnabled'] == true,
    );
  }
}

/// Schedule Provider - Quản lý lịch tưới
class ScheduleProvider with ChangeNotifier {
  static const String _schedulesStorageKey = 'irrigation_schedules';
  static const String _lastEngineCheckStorageKey = 'schedule_last_engine_check';

  SensorProvider _sensorProvider;
  final List<IrrigationSchedule> _schedules = [];
  List<IrrigationSchedule> get schedules => List.unmodifiable(_schedules);
  Timer? _scheduleTimer;
  final Map<String, String> _lastTriggerMinuteBySchedule = {};

  ScheduleProvider(this._sensorProvider) {
    _initialize();
  }

  void updateSensorProvider(SensorProvider sensorProvider) {
    _sensorProvider = sensorProvider;
  }

  Future<void> _initialize() async {
    await _loadSchedules();
    await _syncBackgroundSchedules();
    await _runMissedScheduleIfAny();
    _startScheduleEngine();
    notifyListeners();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_schedulesStorageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _schedules
        ..clear()
        ..addAll(
          decoded
              .whereType<Map<String, dynamic>>()
              .map(IrrigationSchedule.fromJson),
        );
    } catch (_) {
      _schedules.clear();
    }
  }

  Future<void> _persistSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(_schedules.map((s) => s.toJson()).toList());
    await prefs.setString(_schedulesStorageKey, payload);
  }

  Future<void> _syncBackgroundSchedules() async {
    await BackgroundScheduleService.syncSchedules(
      _schedules.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> _persistAndSyncSchedules() async {
    await _persistSchedules();
    await _syncBackgroundSchedules();
  }

  Future<void> _saveLastEngineCheck(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastEngineCheckStorageKey, time.toIso8601String());
  }

  Future<void> _runMissedScheduleIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastCheckRaw = prefs.getString(_lastEngineCheckStorageKey);
    final lastCheck =
        lastCheckRaw != null ? DateTime.tryParse(lastCheckRaw) : null;

    if (lastCheck == null) {
      await _saveLastEngineCheck(now);
      return;
    }

    // Ignore stale windows too far in the past.
    if (now.difference(lastCheck) > const Duration(days: 2)) {
      await _saveLastEngineCheck(now);
      return;
    }

    IrrigationSchedule? latestSchedule;
    DateTime? latestOccurrence;
    for (final schedule in _schedules) {
      if (!schedule.isEnabled) continue;
      final occurrence = _findLatestOccurrenceBetween(
        schedule: schedule,
        fromExclusive: lastCheck,
        toInclusive: now,
      );
      if (occurrence == null) continue;

      if (latestOccurrence == null || occurrence.isAfter(latestOccurrence)) {
        latestOccurrence = occurrence;
        latestSchedule = schedule;
      }
    }

    if (latestSchedule != null && latestOccurrence != null) {
      final minuteKey =
          '${latestOccurrence.year}-${latestOccurrence.month}-${latestOccurrence.day}-${latestOccurrence.hour}-${latestOccurrence.minute}';
      _lastTriggerMinuteBySchedule[latestSchedule.id] = minuteKey;
      _sensorProvider.runScheduledIrrigation(
        durationMinutes: latestSchedule.durationMinutes,
        scheduleName: latestSchedule.name,
        zone: latestSchedule.zone,
      );
    }

    await _saveLastEngineCheck(now);
  }

  DateTime? _findLatestOccurrenceBetween({
    required IrrigationSchedule schedule,
    required DateTime fromExclusive,
    required DateTime toInclusive,
  }) {
    final startDate = DateTime(
      fromExclusive.year,
      fromExclusive.month,
      fromExclusive.day,
    );
    final endDate = DateTime(
      toInclusive.year,
      toInclusive.month,
      toInclusive.day,
    );

    DateTime? latest;
    for (
      DateTime day = startDate;
      !day.isAfter(endDate);
      day = day.add(const Duration(days: 1))
    ) {
      final weekdayIndex = (day.weekday + 6) % 7; // Monday=0 ... Sunday=6
      if (!schedule.days[weekdayIndex]) {
        continue;
      }

      final occurrence = DateTime(
        day.year,
        day.month,
        day.day,
        schedule.time.hour,
        schedule.time.minute,
      );

      final inRange = occurrence.isAfter(fromExclusive) &&
          (occurrence.isAtSameMomentAs(toInclusive) ||
              occurrence.isBefore(toInclusive));
      if (!inRange) {
        continue;
      }

      if (latest == null || occurrence.isAfter(latest)) {
        latest = occurrence;
      }
    }

    return latest;
  }

  void _startScheduleEngine() {
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _checkAndRunSchedules();
    });

    // Chay ngay khi khoi tao de khong bo lo neu app mo dung phut lich.
    _checkAndRunSchedules();
  }

  void _checkAndRunSchedules() {
    final now = DateTime.now();
    final weekdayIndex = (now.weekday + 6) % 7; // Monday=0 ... Sunday=6
    final minuteKey =
        '${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}';

    for (final schedule in _schedules) {
      if (!schedule.isEnabled) continue;
      if (!schedule.days[weekdayIndex]) continue;
      if (schedule.time.hour != now.hour || schedule.time.minute != now.minute) {
        continue;
      }

      final triggerKey = _lastTriggerMinuteBySchedule[schedule.id];
      if (triggerKey == minuteKey) {
        continue;
      }

      _lastTriggerMinuteBySchedule[schedule.id] = minuteKey;
      _sensorProvider.runScheduledIrrigation(
        durationMinutes: schedule.durationMinutes,
        scheduleName: schedule.name,
        zone: schedule.zone,
      );
    }

    unawaited(_saveLastEngineCheck(now));
  }

  void onAppResumed() {
    unawaited(_runMissedScheduleIfAny());
    _checkAndRunSchedules();
  }

  Future<void> addSchedule(IrrigationSchedule schedule) async {
    _schedules.add(schedule);
    await _persistAndSyncSchedules();
    notifyListeners();
  }

  Future<void> updateSchedule(IrrigationSchedule updated) async {
    final idx = _schedules.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _schedules[idx] = updated;
      await _persistAndSyncSchedules();
      notifyListeners();
    }
  }

  Future<void> toggleSchedule(String id) async {
    final idx = _schedules.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _schedules[idx].isEnabled = !_schedules[idx].isEnabled;
      await _persistAndSyncSchedules();
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    _schedules.removeWhere((s) => s.id == id);
    _lastTriggerMinuteBySchedule.remove(id);
    await _persistAndSyncSchedules();
    notifyListeners();
  }

  String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    super.dispose();
  }
}
