import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/sensor_data.dart';
import '../models/irrigation_log.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';

/// Sensor Provider - Quản lý dữ liệu cảm biến và bơm nước
class SensorProvider with ChangeNotifier {
  final String _baseUrl = AppConstants.apiBaseUrl;
  final String _deviceId = 'esp32_garden_01';

  Timer? _refreshTimer;
  Timer? _dailyWeatherTimer;
  Timer? _scheduledStopTimer;
  bool _isFetchingLatest = false;
  bool _isFetchingPumpLatest = false;
  bool _isCheckingDailyWeather = false;
  bool _isFetchingAlerts = false;
  final Set<String> _historyFetchingKeys = {};
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  // ─── Trạng thái bơm ───────────────────────────────────────────────────────
  bool _isPumpOn = false;
  bool _isTogglingPump = false;
  String? _pumpErrorMessage;
  
  bool get isPumpOn => _isPumpOn;
  bool get isToggling => _isTogglingPump;
  String? get pumpErrorMessage => _pumpErrorMessage;
  
  void clearPumpError() {
    _pumpErrorMessage = null;
    notifyListeners();
  }

  // ─── Giá trị hiện tại ─────────────────────────────────────────────────────
  final Map<String, double> _currentReadings = {
    'soil_moisture': 0.0,
    'humidity': 0.0,
    'temperature': 0.0,
    'pressure': 0.0,
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
  final Set<String> _activeThresholdAlerts = <String>{};
  List<Map<String, dynamic>> get alerts => List.unmodifiable(_alerts);
  int get unreadAlertCount => _alerts.where((a) => !(a['isRead'] as bool)).length;

  // ─── Tự động tưới theo độ ẩm ─────────────────────────────────────────────
  bool _isAutoPumping = false;
  DateTime? _lastAutoPumpTime;

  bool get isAutoPumping => _isAutoPumping;

  // ─── Lịch sử tưới nước ────────────────────────────────────────────────────
  final List<IrrigationLog> _irrigationLogs = [];
  List<IrrigationLog> get irrigationLogs => List.unmodifiable(_irrigationLogs);

  // ─── Dữ liệu lịch sử cảm biến ─────────────────────────────────────────────
  final Map<String, List<ChartDataPoint>> _historicalData = {};

  SensorProvider() {
    _loadThresholds().then((_) {
      _fetchAlerts();
      _fetchLatestReadings();
      _fetchLatestPumpState();
      _fetchIrrigationSessions();
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _fetchLatestReadings();
        _fetchLatestPumpState();
      },
    );

    _scheduleDailyWeatherCheck();
    _checkWeatherIfMissedToday();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _dailyWeatherTimer?.cancel();
    _scheduledStopTimer?.cancel();
    super.dispose();
  }

  // ─── Bật/tắt bơm ─────────────────────────────────────────────────────────
  Future<void> togglePump() async {
    // Ngăn chặn toggle lặp lại nhanh
    if (_isTogglingPump) return;
    
    final nextState = !_isPumpOn;
    
    // Người dùng tắt bơm thủ công → hủy chế độ tự động
    if (!nextState && _isAutoPumping) {
      _isAutoPumping = false;
      _lastAutoPumpTime = DateTime.now(); // reset cooldown từ lúc tắt thủ công
    }

    _isTogglingPump = true;
    _pumpErrorMessage = null;
    notifyListeners();
    
    // Chỉ cập nhật local state khi server xác nhận thành công
    final success = await _sendPumpToggle(nextState, triggeredBy: 'manual');
    
    if (success) {
      _setPumpStateLocal(
        nextState,
        triggeredBy: 'manual',
        toggleTime: DateTime.now(),
      );
      _fetchLatestPumpState();
    } else {
      _pumpErrorMessage = 'Không thể điều khiển bơm. Kiểm tra kết nối server';
    }
    
    _isTogglingPump = false;
    notifyListeners();
  }

  void runScheduledIrrigation({
    required int durationMinutes,
    required String scheduleName,
    required String zone,
  }) {
    if (_isPumpOn) {
      return;
    }

    final scheduleTime = DateTime.now(); // Ghi l\u1ea1i th\u1eddi gian ch\u1ea3y schedule ch\u00ednh x\u00e1c
    
    _setPumpStateLocal(
      true,
      triggeredBy: 'schedule',
      scheduleName: scheduleName,
      zone: zone,
      toggleTime: scheduleTime,
    );
    _sendPumpToggle(true, triggeredBy: 'schedule');
    notifyListeners();

    _scheduledStopTimer?.cancel();
    _scheduledStopTimer = Timer(Duration(minutes: durationMinutes), () {
      if (!_isPumpOn) {
        return;
      }
      _setPumpStateLocal(false, triggeredBy: 'schedule');
      _sendPumpToggle(false, triggeredBy: 'schedule');
      notifyListeners();
    });
  }

  // ─── Cập nhật ngưỡng ──────────────────────────────────────────────────────
  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _thresholds.keys.toList()) {
      final saved = prefs.getDouble('threshold_$key');
      if (saved != null) _thresholds[key] = saved;
    }
    notifyListeners();
  }

  Future<void> _saveThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _thresholds.entries) {
      await prefs.setDouble('threshold_${entry.key}', entry.value);
    }
  }

  void updateThreshold(String type, double value) {
    _thresholds[type] = value;
    unawaited(_saveThresholds());
    _evaluateThresholdAlerts();
    notifyListeners();
  }

  // ─── Đánh dấu đọc cảnh báo ───────────────────────────────────────────────
  void markAlertRead(String id) {
    final idx = _alerts.indexWhere((a) => a['id'] == id);
    if (idx != -1) {
      _alerts[idx] = Map<String, dynamic>.from(_alerts[idx])
        ..['isRead'] = true;
      unawaited(_markAlertReadOnServer(id));
      notifyListeners();
    }
  }

  void markAllAlertsRead() {
    for (int i = 0; i < _alerts.length; i++) {
      _alerts[i] = Map<String, dynamic>.from(_alerts[i])..['isRead'] = true;
    }
    unawaited(_markAllAlertsReadOnServer());
    notifyListeners();
  }

  void deleteAlert(String id) {
    final idx = _alerts.indexWhere((a) => a['id'] == id);
    if (idx == -1) {
      return;
    }

    final removed = _alerts.removeAt(idx);
    final sourceKey = removed['sourceKey']?.toString();
    if (sourceKey != null && sourceKey.startsWith('threshold_')) {
      _activeThresholdAlerts.remove(sourceKey);
    }

    unawaited(_deleteAlertOnServer(id));
    notifyListeners();
  }

  void deleteAllAlerts() {
    _alerts.clear();
    _activeThresholdAlerts.clear();
    unawaited(_deleteAllAlertsOnServer());
    notifyListeners();
  }

  void addWeatherRainAlert({
    required String message,
    required DateTime forecastDate,
    required double rainProbability,
    required double rainSum,
    String zone = 'Toan bo khu vuc',
  }) {
    final dateKey =
        '${forecastDate.year}-${forecastDate.month}-${forecastDate.day}';
    final idx = _alerts.indexWhere(
      (a) =>
          a['type'] == 'weather_rain_warning' && a['forecastDateKey'] == dateKey,
    );

    final alert = {
      'id': 'weather_rain_$dateKey',
      'type': 'weather_rain_warning',
      'title': 'Canh bao mua va xu ly muong nuoc',
      'message': message,
      'zone': zone,
      'value': rainProbability,
      'threshold': 50.0,
      'rainSum': rainSum,
      'forecastDateKey': dateKey,
      'sourceKey': 'weather_rain_$dateKey',
      'timestamp': DateTime.now(),
      'isRead': false,
    };

    if (idx != -1) {
      _alerts[idx] = alert;
    } else {
      _alerts.insert(0, alert);
      unawaited(_createAlertOnServer(alert));
      unawaited(_notificationService.showNotification(
        title: alert['title'] as String,
        body: alert['message'] as String,
      ));
    }
    notifyListeners();
  }

  Future<void> _fetchAlerts() async {
    if (_isFetchingAlerts) return;
    _isFetchingAlerts = true;

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/alerts?deviceId=$_deviceId&limit=200'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as List<dynamic>;
      final fetched = data.whereType<Map<String, dynamic>>().map((e) {
        return {
          'id': (e['id'] ?? '').toString(),
          'type': (e['type'] ?? '').toString(),
          'title': (e['title'] ?? '').toString(),
          'message': (e['message'] ?? '').toString(),
          'zone': (e['zone'] ?? 'Vườn rau A').toString(),
          'value': (e['value'] as num?)?.toDouble(),
          'threshold': (e['threshold'] as num?)?.toDouble(),
          'rainSum': (e['rainSum'] as num?)?.toDouble(),
          'forecastDateKey': e['forecastDateKey']?.toString(),
          'sourceKey': e['sourceKey']?.toString(),
          'timestamp': DateTime.tryParse((e['timestamp'] ?? '').toString()) ?? DateTime.now(),
          'isRead': e['isRead'] == true,
        };
      }).toList();

      _alerts
        ..clear()
        ..addAll(fetched);
      notifyListeners();
    } catch (_) {
      // Keep silent when backend is unavailable.
    } finally {
      _isFetchingAlerts = false;
    }
  }

  Future<void> _markAlertReadOnServer(String id) async {
    try {
      await http
          .patch(
            Uri.parse('$_baseUrl/alerts/$id/read'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore to keep UI responsive.
    }
  }

  Future<void> _markAllAlertsReadOnServer() async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/alerts/read-all'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'deviceId': _deviceId}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore to keep UI responsive.
    }
  }

  Future<void> _deleteAlertOnServer(String id) async {
    try {
      await http
          .delete(Uri.parse('$_baseUrl/alerts/$id'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore to keep UI responsive.
    }
  }

  Future<void> _deleteAllAlertsOnServer() async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/alerts/delete-all'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'deviceId': _deviceId}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore to keep UI responsive.
    }
  }

  Future<void> _createAlertOnServer(Map<String, dynamic> alert) async {
    final localId = (alert['id'] ?? '').toString();
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/alerts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': _deviceId,
              'type': alert['type'],
              'title': alert['title'],
              'message': alert['message'],
              'zone': alert['zone'],
              'value': alert['value'],
              'threshold': alert['threshold'],
              'rainSum': alert['rainSum'],
              'forecastDateKey': alert['forecastDateKey'],
              'sourceKey': alert['sourceKey'],
              'isRead': alert['isRead'] == true,
              'timestamp': (alert['timestamp'] as DateTime?)?.toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 201) {
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final serverId = (data['id'] ?? '').toString();
      if (serverId.isEmpty) return;

      final idx = _alerts.indexWhere((a) => (a['id'] ?? '').toString() == localId);
      if (idx != -1) {
        _alerts[idx] = Map<String, dynamic>.from(_alerts[idx])..['id'] = serverId;
        notifyListeners();
      }
    } catch (_) {
      // Ignore to keep UI responsive.
    }
  }

  void _scheduleDailyWeatherCheck() {
    _dailyWeatherTimer?.cancel();

    final now = DateTime.now();
    var nextRun = DateTime(
      now.year,
      now.month,
      now.day,
      AppConstants.dailyWeatherCheckHour,
    );

    if (!now.isBefore(nextRun)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }

    final delay = nextRun.difference(now);
    _dailyWeatherTimer = Timer(delay, () async {
      await _runDailyWeatherCheck();
      _scheduleDailyWeatherCheck();
    });
  }

  Future<void> _checkWeatherIfMissedToday() async {
    final now = DateTime.now();
    if (now.hour < AppConstants.dailyWeatherCheckHour) return;

    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(AppConstants.keyWeatherLastCheckDate);
    if (lastDate == _dateKey(now)) return;

    await _runDailyWeatherCheck();
  }

  Future<void> onAppResumed() async {
    _scheduleDailyWeatherCheck();
    await _checkWeatherIfMissedToday();
  }

  Future<void> _runDailyWeatherCheck() async {
    if (_isCheckingDailyWeather) return;
    _isCheckingDailyWeather = true;

    try {
      final location = await _locationService.getBestEffortLocation();
      final forecast = await _weatherService.getTomorrowForecast(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      final advice = _weatherService.buildDrainageAdvice(forecast);

      if (forecast.shouldTriggerRainAlert) {
        addWeatherRainAlert(
          message: advice,
          forecastDate: forecast.date,
          rainProbability: forecast.rainProbability,
          rainSum: forecast.rainSum,
          zone: location.label,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.keyWeatherLastCheckDate,
        _dateKey(DateTime.now()),
      );
    } catch (_) {
      // Keep silent to avoid affecting sensor flow.
    } finally {
      _isCheckingDailyWeather = false;
    }
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // ─── Lấy dữ liệu lịch sử theo loại và kỳ ─────────────────────────────────
  List<ChartDataPoint> getHistoricalData(String type, String period) {
    final key = '${type}_$period';
    _fetchHistory(type, period);
    return _historicalData[key] ?? _historicalData[type] ?? [];
  }

  Future<void> _fetchLatestReadings() async {
    if (_isFetchingLatest) return;
    _isFetchingLatest = true;

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/sensors/latest?deviceId=$_deviceId'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      _currentReadings['soil_moisture'] =
          (data['soil_moisture'] as num?)?.toDouble() ?? _currentReadings['soil_moisture']!;
      _currentReadings['humidity'] =
          (data['humidity'] as num?)?.toDouble() ?? _currentReadings['humidity']!;
      _currentReadings['temperature'] =
          (data['temperature'] as num?)?.toDouble() ?? _currentReadings['temperature']!;
      _currentReadings['pressure'] =
          (data['pressure'] as num?)?.toDouble() ?? _currentReadings['pressure']!;

      _evaluateThresholdAlerts();

      notifyListeners();
    } catch (_) {
      // Giữ dữ liệu hiện tại nếu backend chưa sẵn sàng.
    } finally {
      _isFetchingLatest = false;
    }
  }

  Future<void> _fetchLatestPumpState() async {
    if (_isFetchingPumpLatest) return;
    _isFetchingPumpLatest = true;

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/pump/latest?deviceId=$_deviceId'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestPumpOn = data['isOn'] == true;
      if (!_isTogglingPump && latestPumpOn != _isPumpOn) {
        _setPumpStateLocal(
          latestPumpOn,
          triggeredBy: (data['triggeredBy'] ?? 'auto').toString(),
          toggleTime: DateTime.tryParse((data['timestamp'] ?? '').toString()),
        );
        if (!latestPumpOn) {
          _fetchIrrigationSessions();
        }
        notifyListeners();
      }
    } catch (_) {
      // Ignore; keep current UI state.
    } finally {
      _isFetchingPumpLatest = false;
    }
  }

  void _evaluateThresholdAlerts() {
    _checkThreshold(
      type: 'soil_moisture',
      title: 'Độ ẩm đất thấp',
      messageBuilder: (value, threshold) =>
          'Độ ẩm đất đang ở mức ${value.toStringAsFixed(1)}% - dưới ngưỡng ${threshold.toStringAsFixed(1)}%',
      zone: 'Vườn rau A',
      isTriggered: (value, threshold) => value < threshold,
    );

    _checkThreshold(
      type: 'humidity',
      title: 'Độ ẩm không khí thấp',
      messageBuilder: (value, threshold) =>
          'Độ ẩm không khí đang ở mức ${value.toStringAsFixed(1)}% - thấp hơn ngưỡng ${threshold.toStringAsFixed(1)}%',
      zone: 'Vườn rau A',
      isTriggered: (value, threshold) => value < threshold,
    );

    _checkThreshold(
      type: 'temperature',
      title: 'Nhiệt độ cao bất thường',
      messageBuilder: (value, threshold) =>
          'Nhiệt độ hiện tại ${value.toStringAsFixed(1)}°C - vượt ngưỡng ${threshold.toStringAsFixed(1)}°C',
      zone: 'Vườn rau A',
      isTriggered: (value, threshold) => value > threshold,
    );

    _checkThreshold(
      type: 'pressure',
      title: 'Áp suất thấp',
      messageBuilder: (value, threshold) =>
          'Áp suất hiện tại ${value.toStringAsFixed(1)} hPa - dưới ngưỡng ${threshold.toStringAsFixed(1)} hPa',
      zone: 'Vườn rau A',
      isTriggered: (value, threshold) => value < threshold,
    );

    _checkAutoIrrigation();
  }

  void _checkThreshold({
    required String type,
    required String title,
    required String Function(double value, double threshold) messageBuilder,
    required String zone,
    required bool Function(double value, double threshold) isTriggered,
  }) {
    final value = _currentReadings[type];
    final threshold = _thresholds[type];
    if (value == null || threshold == null) {
      return;
    }

    final triggered = isTriggered(value, threshold);
    final key = 'threshold_$type';

    if (triggered) {
      if (_activeThresholdAlerts.contains(key)) {
        return;
      }

      _alerts.insert(
        0,
        {
          'id': '${key}_${DateTime.now().millisecondsSinceEpoch}',
          'type': type,
          'title': title,
          'message': messageBuilder(value, threshold),
          'zone': zone,
          'value': value,
          'threshold': threshold,
          'sourceKey': key,
          'timestamp': DateTime.now(),
          'isRead': false,
        },
      );
      final newAlert = _alerts.first;
      unawaited(_createAlertOnServer(newAlert));
      unawaited(_notificationService.showNotification(
        title: newAlert['title'] as String,
        body: newAlert['message'] as String,
      ));
      _activeThresholdAlerts.add(key);
      return;
    }

    _activeThresholdAlerts.remove(key);
  }

  /// Tự động bật/tắt bơm dựa theo độ ẩm đất.
  /// - Bật khi: độ ẩm < ngưỡng AND bơm đang tắt AND cooldown 30 phút đã qua.
  /// - Tắt khi: độ ẩm >= ngưỡng AND đang bơm tự động.
  void _checkAutoIrrigation() {
    final moisture = _currentReadings['soil_moisture'];
    final threshold = _thresholds['soil_moisture'];
    if (moisture == null || threshold == null) return;

    final belowThreshold = moisture < threshold;

    if (belowThreshold) {
      // Đã bơm rồi (tự động hoặc thủ công) → không bật thêm
      if (_isPumpOn) return;
      // Kiểm tra cooldown 30 phút
      if (_lastAutoPumpTime != null &&
          DateTime.now().difference(_lastAutoPumpTime!) <
              const Duration(minutes: 30)) {
        return;
      }

      // Bật bơm tự động
      _isAutoPumping = true;
      _lastAutoPumpTime = DateTime.now();
      final startTime = DateTime.now();
      _sendPumpToggle(true, triggeredBy: 'auto_moisture').then((success) {
        if (success) {
          _setPumpStateLocal(
            true,
            triggeredBy: 'auto_moisture',
            zone: 'Vườn rau A',
            toggleTime: startTime,
          );
        } else {
          _isAutoPumping = false;
          _lastAutoPumpTime = null;
        }
        notifyListeners();
      });
    } else {
      // Độ ẩm đã phục hồi → tắt bơm nếu đang ở chế độ tự động
      if (_isAutoPumping && _isPumpOn) {
        _isAutoPumping = false;
        _sendPumpToggle(false, triggeredBy: 'auto_moisture');
        _setPumpStateLocal(false, triggeredBy: 'auto_moisture');
        notifyListeners();
      }
    }
  }

  Future<void> _fetchHistory(String type, String period) async {
    final key = '${type}_$period';
    if (_historyFetchingKeys.contains(key)) {
      return;
    }

    _historyFetchingKeys.add(key);
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/sensors/history?deviceId=$_deviceId&type=$type&period=$period'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      final points = data
          .whereType<Map<String, dynamic>>()
          .map((e) {
            final rawTime = (e['time'] ?? '').toString();
            final parsed = DateTime.tryParse(rawTime);
            final localTime = parsed != null
                ? (parsed.isUtc ? parsed.toLocal() : parsed)
                : DateTime.now();
            return ChartDataPoint(
              time: localTime,
              value: (e['value'] as num?)?.toDouble() ?? 0,
            );
          })
          .toList();

      if (points.isNotEmpty) {
        _historicalData[key] = points;
        _historicalData[type] = points;
        notifyListeners();
      }
    } catch (_) {
      // Không throw để tránh ảnh hưởng UI hiện tại.
    } finally {
      _historyFetchingKeys.remove(key);
    }
  }

  Future<bool> _sendPumpToggle(bool isOn, {String triggeredBy = 'manual'}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/pump/toggle'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': _deviceId,
              'isOn': isOn,
              'triggeredBy': triggeredBy,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true; // Thành công
      } else {
        print('Pump toggle API error: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } on TimeoutException catch (_) {
      print('Pump toggle timeout');
      return false;
    } catch (e) {
      print('Pump toggle error: $e');
      return false;
    }
  }

  void _setPumpStateLocal(
    bool isOn, {
    required String triggeredBy,
    String? scheduleName,
    String? zone,
    DateTime? toggleTime,
  }) {
    final stateChanged = _isPumpOn != isOn;
    _isPumpOn = isOn;
    
    if (!stateChanged) {
      return; // Không thay đổi state, skip logging
    }
    
    // Sử dụng toggleTime nếu có (từ user tap), không thì dùng now()
    final effectiveTime = toggleTime ?? DateTime.now();
    
    if (_isPumpOn) {
      // Bắt đầu phiên tưới mới
      _irrigationLogs.insert(
        0,
        IrrigationLog(
          id: effectiveTime.millisecondsSinceEpoch.toString(),
          deviceId: 'pump_01',
          deviceName: 'Máy bơm 1',
          startTime: effectiveTime,
          triggeredBy: triggeredBy,
          scheduleName: scheduleName,
          zone: zone ?? 'Vườn rau A',
        ),
      );
    } else {
      // Kết thúc lần tưới gần nhất
      final idx = _irrigationLogs.indexWhere(
        (l) => l.deviceId == 'pump_01' && l.endTime == null,
      );
      if (idx != -1) {
        final log = _irrigationLogs[idx];
        final end = effectiveTime; // Sử dụng effectiveTime làm endTime
        final secs = end.difference(log.startTime).inSeconds;
        final mins = secs ~/ 60;
        _irrigationLogs[idx] = IrrigationLog(
          id: log.id,
          deviceId: log.deviceId,
          deviceName: log.deviceName,
          startTime: log.startTime,
          endTime: end,
          flowAmount: mins * 12.0,
          triggeredBy: log.triggeredBy,
          zone: log.zone,
        );
        
        // Gửi session lên server
        _uploadIrrigationSession(_irrigationLogs[idx]);
      }
    }
  }
  
  Future<void> _uploadIrrigationSession(IrrigationLog log) async {
    if (log.endTime == null) return;
    
    final durationSecs = log.endTime!.difference(log.startTime).inSeconds;

    try {
      await http.post(
        Uri.parse('$_baseUrl/pump/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': _deviceId,
          'durationSeconds': durationSecs,
          'triggeredBy': log.triggeredBy,
          'startTime': log.startTime.toIso8601String(),
          'endTime': log.endTime?.toIso8601String(),
        }),
      );
    } catch (e) {
      print('Failed to upload irrigation session: $e');
    }
  }

  void deleteIrrigationSession(String id) {
    final idx = _irrigationLogs.indexWhere((l) => l.id == id);
    if (idx == -1) {
      return;
    }

    _irrigationLogs.removeAt(idx);
    unawaited(_deleteIrrigationSessionOnServer(id));
    notifyListeners();
  }

  void deleteAllIrrigationSessions() {
    _irrigationLogs.clear();
    unawaited(_deleteAllIrrigationSessionsOnServer());
    notifyListeners();
  }

  Future<void> _deleteIrrigationSessionOnServer(String id) async {
    final objectIdPattern = RegExp(r'^[0-9a-fA-F]{24}$');
    if (!objectIdPattern.hasMatch(id)) {
      return;
    }

    try {
      await http
          .delete(Uri.parse('$_baseUrl/pump/sessions/$id'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore to keep UI responsive.
    }
  }

  Future<void> _deleteAllIrrigationSessionsOnServer() async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/pump/sessions/delete-all'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'deviceId': _deviceId}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore to keep UI responsive.
    }
  }

  bool _isFetchingSessions = false;

  Future<void> _fetchIrrigationSessions() async {
    if (_isFetchingSessions) return;
    _isFetchingSessions = true;
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/pump/sessions?deviceId=$_deviceId&limit=50'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as List<dynamic>;
      final fetched = data.whereType<Map<String, dynamic>>().map((e) {
        final durSecs = (e['durationSeconds'] as num?)?.toInt() ?? 0;
        final durMins = durSecs ~/ 60;
        return IrrigationLog(
          id: e['id'] as String,
          deviceId: e['deviceId'] as String,
          deviceName: 'Máy bơm 1',
          startTime: DateTime.tryParse((e['startTime'] ?? '').toString()) ?? DateTime.now(),
          endTime: DateTime.tryParse((e['endTime'] ?? '').toString()),
          flowAmount: durMins * 12.0,
          triggeredBy: e['triggeredBy'] as String? ?? 'auto',
          zone: 'Vườn rau A',
        );
      }).toList();

      _irrigationLogs
        ..clear()
        ..addAll(fetched);
      notifyListeners();
    } catch (_) {
      // Giữ dữ liệu hiện tại nếu server chưa sẵn sàng.
    } finally {
      _isFetchingSessions = false;
    }
  }

}

