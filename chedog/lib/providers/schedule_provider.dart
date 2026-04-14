import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
        !days[6]) return 'Ngày trong tuần';
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
  final List<IrrigationSchedule> _schedules = [];
  List<IrrigationSchedule> get schedules => List.unmodifiable(_schedules);

  ScheduleProvider() {
    _loadMockSchedules();
  }

  void _loadMockSchedules() {
    _schedules.addAll([
      IrrigationSchedule(
        id: 's1',
        name: 'Tưới buổi sáng',
        time: const TimeOfDay(hour: 6, minute: 0),
        days: [true, true, true, true, true, true, true],
        durationMinutes: 15,
        zone: 'Vườn rau A',
        isEnabled: true,
      ),
      IrrigationSchedule(
        id: 's2',
        name: 'Tưới chiều',
        time: const TimeOfDay(hour: 17, minute: 30),
        days: [true, true, true, true, true, false, false],
        durationMinutes: 10,
        zone: 'Vườn hoa B',
        isEnabled: true,
      ),
      IrrigationSchedule(
        id: 's3',
        name: 'Tưới nhà kính',
        time: const TimeOfDay(hour: 8, minute: 0),
        days: [false, false, false, false, false, true, true],
        durationMinutes: 20,
        zone: 'Nhà kính C',
        isEnabled: false,
      ),
    ]);
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
}
