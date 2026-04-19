import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
}

/// Schedule Provider - Quản lý lịch tưới
class ScheduleProvider with ChangeNotifier {
  SensorProvider _sensorProvider;
  final List<IrrigationSchedule> _schedules = [];
  List<IrrigationSchedule> get schedules => List.unmodifiable(_schedules);
  Timer? _scheduleTimer;
  final Map<String, String> _lastTriggerMinuteBySchedule = {};

  ScheduleProvider(this._sensorProvider) {
    _startScheduleEngine();
  }

  void updateSensorProvider(SensorProvider sensorProvider) {
    _sensorProvider = sensorProvider;
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
  }

  void onAppResumed() {
    _checkAndRunSchedules();
  }

  void addSchedule(IrrigationSchedule schedule) {
    _schedules.add(schedule);
    notifyListeners();
  }

  void updateSchedule(IrrigationSchedule updated) {
    final idx = _schedules.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _schedules[idx] = updated;
      notifyListeners();
    }
  }

  void toggleSchedule(String id) {
    final idx = _schedules.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _schedules[idx].isEnabled = !_schedules[idx].isEnabled;
      notifyListeners();
    }
  }

  void deleteSchedule(String id) {
    _schedules.removeWhere((s) => s.id == id);
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
