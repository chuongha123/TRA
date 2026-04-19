import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/sensor_provider.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  String? _error;
  WeatherForecast? _forecast;
  String? _advice;
  String _locationLabel = AppConstants.weatherLocationName;
  String? _locationFallbackReason;
  bool _usingDeviceLocation = false;

  @override
  void initState() {
    super.initState();
    _loadWeatherAndAdvice();
  }

  Future<void> _loadWeatherAndAdvice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await (() async {
        final location = await _locationService.getBestEffortLocation();
        final forecast = await _weatherService.getTomorrowForecast(
          latitude: location.latitude,
          longitude: location.longitude,
        );
        final advice = _weatherService.buildDrainageAdvice(forecast);
        return (location, forecast, advice);
      })().timeout(const Duration(seconds: 20));

      final location = result.$1;
      final forecast = result.$2;
      final advice = result.$3;

      if (!mounted) return;

      final sensorProvider = context.read<SensorProvider>();
      if (forecast.shouldTriggerRainAlert) {
        sensorProvider.addWeatherRainAlert(
          message: advice,
          forecastDate: forecast.date,
          rainProbability: forecast.rainProbability,
          rainSum: forecast.rainSum,
          zone: location.label,
        );
      }

      setState(() {
        _forecast = forecast;
        _advice = advice;
        _locationLabel = location.label;
        _usingDeviceLocation = location.fromDevice;
        _locationFallbackReason = location.fallbackReason;
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'Hệ thống phản hồi chậm. Vui lòng thử lại.';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dự báo thời tiết'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadWeatherAndAdvice,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56),
              const SizedBox(height: 12),
              const Text(
                'Không tải được dự báo thời tiết',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _loadWeatherAndAdvice,
                child: const Text('Thử lại'),
              )
            ],
          ),
        ),
      );
    }

    final forecast = _forecast!;
    final dateText = DateFormat('dd/MM/yyyy').format(forecast.date);

    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dự báo ngày mai - $dateText',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Khu vực: $_locationLabel'),
                const SizedBox(height: 10),
                _metricRow('Nhiệt độ',
                    '${forecast.minTemp.toStringAsFixed(1)}°C - ${forecast.maxTemp.toStringAsFixed(1)}°C'),
                _metricRow('Xác suất mưa',
                    '${forecast.rainProbability.toStringAsFixed(0)}%'),
                _metricRow(
                    'Lượng mưa dự kiến', '${forecast.rainSum.toStringAsFixed(1)} mm'),
                _metricRow('Tổng quan', forecast.summary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: forecast.mayRain
              ? Colors.orange.withValues(alpha: 0.12)
              : Colors.green.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  forecast.mayRain ? Icons.warning_amber_rounded : Icons.check_circle,
                  color: forecast.mayRain ? Colors.orange.shade800 : Colors.green,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _advice ??
                        'Không có khuyến nghị từ AI, vui lòng tải lại dự báo.',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (forecast.mayRain) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Cách xử lý mương nước để tránh ngập',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Vớt sạch rác, lá cây, bùn ở miệng và đáy mương.'),
                  SizedBox(height: 4),
                  Text('2. Khơi thông các điểm tắc và mở đường thoát nước chính.'),
                  SizedBox(height: 4),
                  Text('3. Gia cố bờ mương, đặt bao cát tại các điểm thấp.'),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (forecast.isFallback)
          Text(
            'Đang dùng dữ liệu dự phòng vì không kết nối được API thời tiết.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        if (forecast.isFallback) const SizedBox(height: 8),
        if (!_usingDeviceLocation && _locationFallbackReason != null) ...[
          const SizedBox(height: 4),
          Text(
            'Lý do: $_locationFallbackReason',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ]
      ],
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
