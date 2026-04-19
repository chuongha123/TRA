/// App Constants - Các hằng số của ứng dụng
/// 
/// Environment Variables Support:
/// Để sử dụng biến môi trường, compile với:
/// flutter run --dart-define=API_BASE_URL="http://YOUR_SERVER:3000/api"
/// flutter run --dart-define=WEBSOCKET_URL="ws://YOUR_SERVER:3000"
/// flutter run --dart-define=ESP32_HOST="192.168.1.100"
///
class AppConstants {
  // App Info
  static const String appName = 'AgriFlow';
  static const String appVersion = '1.0.0';
  
  // API Configuration with environment variable support
  // Default: Android emulator, change for real device/server
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
  static const String websocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'ws://10.0.2.2:3000',
  );
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Weather defaults (TP.HCM)
  static const double weatherLatitude = 10.8231;
  static const double weatherLongitude = 106.6297;
  static const String weatherLocationName = 'TP. Ho Chi Minh';
  
  // ESP32 Configuration with environment variable support
  static const String esp32DefaultHost = String.fromEnvironment(
    'ESP32_HOST',
    defaultValue: '192.168.1.100',
  );
  static const int esp32DefaultPort = 80;
  
  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserToken = 'user_token';
  static const String keyUserId = 'user_id';
  static const String keyUsername = 'username';
  static const String keyDevices = 'devices';
  static const String keyWeatherLastCheckDate = 'weather_last_check_date';

  // Daily auto weather check
  static const int dailyWeatherCheckHour = 6;
  
  // Device Types - Thiết bị nông nghiệp
  static const String deviceTypePump = 'pump';              // Máy bơm nước
  static const String deviceTypeValve = 'valve';            // Van tưới
  static const String deviceTypeSoilSensor = 'soil_sensor'; // Cảm biến độ ẩm đất
  static const String deviceTypeTempHumid = 'temp_humid';   // Cảm biến nhiệt độ/độ ẩm
  static const String deviceTypeController = 'controller';   // Bộ điều khiển ESP32
  
  // Zones - Các khu vực canh tác
  static const List<String> availableZones = [
    'Vườn rau A',
    'Vườn hoa B',
    'Nhà kính C',
    'Vườn cây ăn quả',
  ];
  
  // Sensor Types
  static const String sensorTypeSoilMoisture = 'soil_moisture';     // Độ ẩm đất
  static const String sensorTypeTemperature = 'temperature';         // Nhiệt độ
  static const String sensorTypeHumidity = 'humidity';               // Độ ẩm không khí
  
  // Time Format
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Chart Configuration
  static const int chartMaxDataPoints = 30;
  static const Duration chartUpdateInterval = Duration(seconds: 5);
  
  // Notification
  static const String notificationChannelId = 'smart_agriculture_channel';
  static const String notificationChannelName = 'Smart Agriculture Notifications';
  
  // Animation Duration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 3);
  
  // Padding & Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // Icon Size
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  
  // Device Card Size
  static const double deviceCardHeight = 120.0;
  static const double deviceCardWidth = 160.0;
}
