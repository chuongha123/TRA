import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/irrigation_log.dart';

/// Sensor Provider - Quản lý dữ liệu cảm biến và bơm nước
class SensorProvider with ChangeNotifier {
  // ─── Trạng thái bơm ───────────────────────────────────────────────────────
  bool _isPumpOn = false;
  bool get isPumpOn => _isPumpOn;

  // ─── Giá trị hiện tại ─────────────────────────────────────────────────────
  final Map<String, double> _currentReadings = {
    'soil_moisture': 62.5,
    'humidity': 73.0,
    'temperature': 29.3,
    'pressure': 1013.2,
  };

  Map<String, double> get currentReadings =>
      Map.unmodifiable(_currentReadings);

  double get soilMoisture => _currentReadings['soil_moisture']!;
  double get humidity => _currentReadings['humidity']!;
  double get temperature => _currentReadings['temperature']!;
  double get pressure => _currentReadings['pressure']!;

  // ─── Ngưỡng cảnh báo ──────────────────────────────────────────────────────
  final Map<String, double> _thresholds = {
    'soil_moisture': 30.0, // % - dưới ngưỡng => cảnh báo
    'humidity': 40.0, // % - dưới ngưỡng => cảnh báo
    'temperature': 38.0, // °C - trên ngưỡng => cảnh báo
    'pressure': 1000.0, // hPa - dưới ngưỡng => cảnh báo
  };

  Map<String, double> get thresholds => Map.unmodifiable(_thresholds);

  // ─── Danh sách cảnh báo ──────────────────────────────────────────────────
  final List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> get alerts => List.unmodifiable(_alerts);
  int get unreadAlertCount => _alerts.where((a) => !(a['isRead'] as bool)).length;

  // ─── Lịch sử tưới nước ────────────────────────────────────────────────────
  final List<IrrigationLog> _irrigationLogs = [];
  List<IrrigationLog> get irrigationLogs => List.unmodifiable(_irrigationLogs);

  // ─── Dữ liệu lịch sử cảm biến ─────────────────────────────────────────────
  final Map<String, List<ChartDataPoint>> _historicalData = {};

  SensorProvider() {
    _generateMockData();
    _generateMockIrrigationLogs();
    _generateMockAlerts();
  }

  // ─── Bật/tắt bơm ─────────────────────────────────────────────────────────
  void togglePump() {
    _isPumpOn = !_isPumpOn;
    if (_isPumpOn) {
      _irrigationLogs.insert(
        0,
        IrrigationLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          deviceId: 'pump_01',
          deviceName: 'Máy bơm 1',
          startTime: DateTime.now(),
          triggeredBy: 'manual',
          zone: 'Vườn rau A',
        ),
      );
    } else {
      // Kết thúc lần tưới gần nhất
      final idx = _irrigationLogs.indexWhere(
        (l) => l.deviceId == 'pump_01' && l.endTime == null,
      );
      if (idx != -1) {
        final log = _irrigationLogs[idx];
        final end = DateTime.now();
        final mins = end.difference(log.startTime).inMinutes;
        _irrigationLogs[idx] = IrrigationLog(
          id: log.id,
          deviceId: log.deviceId,
          deviceName: log.deviceName,
          startTime: log.startTime,
          endTime: end,
          flowAmount: mins * 12.0, // ~12L/phút
          triggeredBy: log.triggeredBy,
          zone: log.zone,
        );
      }
    }
    notifyListeners();
  }

  // ─── Cập nhật ngưỡng ──────────────────────────────────────────────────────
  void updateThreshold(String type, double value) {
    _thresholds[type] = value;
    notifyListeners();
  }

  // ─── Đánh dấu đọc cảnh báo ───────────────────────────────────────────────
  void markAlertRead(String id) {
    final idx = _alerts.indexWhere((a) => a['id'] == id);
    if (idx != -1) {
      _alerts[idx] = Map<String, dynamic>.from(_alerts[idx])
        ..['isRead'] = true;
      notifyListeners();
    }
  }

  void markAllAlertsRead() {
    for (int i = 0; i < _alerts.length; i++) {
      _alerts[i] = Map<String, dynamic>.from(_alerts[i])..['isRead'] = true;
    }
    notifyListeners();
  }

  // ─── Lấy dữ liệu lịch sử theo loại và kỳ ─────────────────────────────────
  List<ChartDataPoint> getHistoricalData(String type, String period) {
    final key = '${type}_$period';
    return _historicalData[key] ?? _historicalData[type] ?? [];
  }

  // ─── Tạo dữ liệu mock ─────────────────────────────────────────────────────
  void _generateMockData() {
    final rng = Random(42);
    final now = DateTime.now();

    for (final period in ['6h', '24h', '7d', '30d']) {
      int pointCount;
      Duration interval;
      switch (period) {
        case '6h':
          pointCount = 36; // mỗi 10 phút
          interval = const Duration(minutes: 10);
          break;
        case '24h':
          pointCount = 48; // mỗi 30 phút
          interval = const Duration(minutes: 30);
          break;
        case '7d':
          pointCount = 56; // mỗi 3 giờ
          interval = const Duration(hours: 3);
          break;
        default: // 30d
          pointCount = 60; // mỗi 12 giờ
          interval = const Duration(hours: 12);
      }

      final sm = <ChartDataPoint>[];
      final hum = <ChartDataPoint>[];
      final temp = <ChartDataPoint>[];
      final pres = <ChartDataPoint>[];

      for (int i = pointCount; i >= 0; i--) {
        final t = now.subtract(interval * i);
        final hour = t.hour + t.minute / 60.0;

        // Độ ẩm đất: thấp lúc trưa, cao sau tưới
        final smBase = 55.0 + 15 * sin((hour - 6) * pi / 12);
        sm.add(ChartDataPoint(
          time: t,
          value: (smBase + rng.nextDouble() * 6 - 3).clamp(20, 90),
        ));

        // Độ ẩm không khí: cao sáng/tối, thấp trưa
        final humBase = 70.0 - 20 * sin((hour - 6) * pi / 12);
        hum.add(ChartDataPoint(
          time: t,
          value: (humBase + rng.nextDouble() * 8 - 4).clamp(30, 95),
        ));

        // Nhiệt độ: thấp sáng sớm, cao trưa (25-35°C)
        final tempBase = 27.0 + 6 * sin((hour - 6) * pi / 12);
        temp.add(ChartDataPoint(
          time: t,
          value: (tempBase + rng.nextDouble() * 2 - 1).clamp(18, 40),
        ));

        // Áp suất: biến đổi chậm
        pres.add(ChartDataPoint(
          time: t,
          value: (1013.0 + 5 * sin(i * 0.3) + rng.nextDouble() * 2 - 1)
              .clamp(995, 1030),
        ));
      }

      _historicalData['soil_moisture_$period'] = sm;
      _historicalData['humidity_$period'] = hum;
      _historicalData['temperature_$period'] = temp;
      _historicalData['pressure_$period'] = pres;
    }

    // dữ liệu mặc định (24h)
    _historicalData['soil_moisture'] = _historicalData['soil_moisture_24h']!;
    _historicalData['humidity'] = _historicalData['humidity_24h']!;
    _historicalData['temperature'] = _historicalData['temperature_24h']!;
    _historicalData['pressure'] = _historicalData['pressure_24h']!;
  }

  void _generateMockIrrigationLogs() {
    final now = DateTime.now();
    _irrigationLogs.addAll([
      IrrigationLog(
        id: '1',
        deviceId: 'pump_01',
        deviceName: 'Máy bơm 1',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1, minutes: 45)),
        flowAmount: 180.0,
        triggeredBy: 'schedule',
        scheduleName: 'Tưới buổi sáng',
        zone: 'Vườn rau A',
      ),
      IrrigationLog(
        id: '2',
        deviceId: 'pump_01',
        deviceName: 'Máy bơm 1',
        startTime: now.subtract(const Duration(hours: 8)),
        endTime: now.subtract(const Duration(hours: 7, minutes: 40)),
        flowAmount: 240.0,
        triggeredBy: 'schedule',
        scheduleName: 'Tưới sáng sớm',
        zone: 'Vườn rau A',
      ),
      IrrigationLog(
        id: '3',
        deviceId: 'valve_02',
        deviceName: 'Van tưới 2',
        startTime: now.subtract(const Duration(days: 1, hours: 5)),
        endTime: now.subtract(const Duration(days: 1, hours: 4, minutes: 50)),
        flowAmount: 120.0,
        triggeredBy: 'auto',
        zone: 'Vườn hoa B',
      ),
      IrrigationLog(
        id: '4',
        deviceId: 'pump_01',
        deviceName: 'Máy bơm 1',
        startTime: now.subtract(const Duration(days: 1, hours: 14)),
        endTime: now.subtract(const Duration(days: 1, hours: 13, minutes: 50)),
        flowAmount: 120.0,
        triggeredBy: 'manual',
        zone: 'Vườn rau A',
      ),
      IrrigationLog(
        id: '5',
        deviceId: 'valve_02',
        deviceName: 'Van tưới 2',
        startTime: now.subtract(const Duration(days: 2, hours: 7)),
        endTime: now.subtract(const Duration(days: 2, hours: 6, minutes: 45)),
        flowAmount: 180.0,
        triggeredBy: 'schedule',
        scheduleName: 'Tưới buổi sáng',
        zone: 'Vườn hoa B',
      ),
    ]);
  }

  void _generateMockAlerts() {
    final now = DateTime.now();
    _alerts.addAll([
      {
        'id': 'a1',
        'type': 'soil_moisture',
        'title': 'Độ ẩm đất thấp',
        'message': 'Độ ẩm đất Vườn rau A đang ở mức 25% - dưới ngưỡng an toàn 30%',
        'zone': 'Vườn rau A',
        'value': 25.0,
        'threshold': 30.0,
        'timestamp': now.subtract(const Duration(minutes: 15)),
        'isRead': false,
      },
      {
        'id': 'a2',
        'type': 'temperature',
        'title': 'Nhiệt độ cao bất thường',
        'message': 'Nhiệt độ Nhà kính C vượt 39°C - trên ngưỡng cho phép 38°C',
        'zone': 'Nhà kính C',
        'value': 39.2,
        'threshold': 38.0,
        'timestamp': now.subtract(const Duration(hours: 1)),
        'isRead': false,
      },
      {
        'id': 'a3',
        'type': 'humidity',
        'title': 'Độ ẩm không khí thấp',
        'message': 'Độ ẩm không khí Nhà kính C còn 35% - cần tưới phun sương',
        'zone': 'Nhà kính C',
        'value': 35.0,
        'threshold': 40.0,
        'timestamp': now.subtract(const Duration(hours: 3)),
        'isRead': true,
      },
    ]);
  }
}
