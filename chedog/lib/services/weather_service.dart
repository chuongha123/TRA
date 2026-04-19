import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class WeatherForecast {
  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  final double rainProbability;
  final double rainSum;
  final bool isFallback;

  const WeatherForecast({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    required this.rainProbability,
    required this.rainSum,
    this.isFallback = false,
  });

  bool get mayRain => rainProbability >= 50 || rainSum >= 1;
  bool get shouldTriggerRainAlert => rainProbability >= 70;

  String get summary {
    final weatherLabel = _mapWeatherCode(weatherCode);
    return '$weatherLabel, ${minTemp.toStringAsFixed(1)}-${maxTemp.toStringAsFixed(1)}°C, '
        'mưa ${rainProbability.toStringAsFixed(0)}%';
  }

  static String _mapWeatherCode(int code) {
    if (code == 0) return 'Trời quang';
    if (code >= 1 && code <= 3) return 'Nhiều mây';
    if (code >= 45 && code <= 48) return 'Sương mù';
    if (code >= 51 && code <= 67) return 'Mưa nhỏ';
    if (code >= 71 && code <= 77) return 'Tuyết';
    if (code >= 80 && code <= 82) return 'Mưa rào';
    if (code >= 95 && code <= 99) return 'Mưa dông, giông';
    return 'Thời tiết thay đổi';
  }
}

class WeatherService {
  Future<WeatherForecast> getTomorrowForecast({
    double latitude = AppConstants.weatherLatitude,
    double longitude = AppConstants.weatherLongitude,
  }) async {
    try {
      final uri = Uri.parse(AppConstants.openMeteoBaseUrl).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'daily':
              'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,rain_sum',
          'timezone': 'auto',
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return _fallbackForecast();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>?;
      if (daily == null) {
        return _fallbackForecast();
      }

      final times = (daily['time'] as List<dynamic>? ?? []).cast<String>();
      final weatherCodes = (daily['weather_code'] as List<dynamic>? ?? []);
      final maxTemps = (daily['temperature_2m_max'] as List<dynamic>? ?? []);
      final minTemps = (daily['temperature_2m_min'] as List<dynamic>? ?? []);
      final rainProb =
          (daily['precipitation_probability_max'] as List<dynamic>? ?? []);
      final rainSums = (daily['rain_sum'] as List<dynamic>? ?? []);

      if (times.length < 2 ||
          weatherCodes.length < 2 ||
          maxTemps.length < 2 ||
          minTemps.length < 2 ||
          rainProb.length < 2 ||
          rainSums.length < 2) {
        return _fallbackForecast();
      }

      return WeatherForecast(
        date: DateTime.parse(times[1]),
        weatherCode: (weatherCodes[1] as num).toInt(),
        maxTemp: (maxTemps[1] as num).toDouble(),
        minTemp: (minTemps[1] as num).toDouble(),
        rainProbability: (rainProb[1] as num).toDouble(),
        rainSum: (rainSums[1] as num).toDouble(),
      );
    } catch (_) {
      return _fallbackForecast();
    }
  }

  String buildDrainageAdvice(WeatherForecast forecast) {
    if (forecast.mayRain) {
      return 'Ngày mai có mưa, hãy dọn sạch đường mương. '
          'Cách xử lý: 1) Vớt rác, lá cây, bùn tại miệng mương. '
          '2) Khơi thông các điểm tắc và mở đường thoát nước xuống kênh chính. '
          '3) Gia cố bờ mương, đặt bao cát tại điểm thấp để tránh tràn nước vào vườn.';
    }
    return 'Ngày mai ít khả năng mưa, nên kiểm tra hệ thống tưới và bổ sung nước hợp lý.';
  }

  WeatherForecast _fallbackForecast() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return WeatherForecast(
      date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
      weatherCode: 3,
      maxTemp: 34.0,
      minTemp: 26.0,
      rainProbability: 40.0,
      rainSum: 0.0,
      isFallback: true,
    );
  }
}
