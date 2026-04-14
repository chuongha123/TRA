/// App Constants - Các hằng số của ứng dụng
class AppConstants {
  // App Info
  static const String appName = 'Smart Agriculture IoT';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String apiBaseUrl = 'https://api.smartfarm.com';
  static const String websocketUrl = 'wss://ws.smartfarm.com';
  
  // ESP32 Configuration
  static const String esp32DefaultHost = '192.168.1.100';
  static const int esp32DefaultPort = 80;
  
  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserToken = 'user_token';
  static const String keyUserId = 'user_id';
  static const String keyUsername = 'username';
  static const String keyDevices = 'devices';
  
  // Device Types - Thiết bị nông nghiệp
  static const String deviceTypePump = 'pump';              // Máy bơm nước
  static const String deviceTypeValve = 'valve';            // Van tưới
  static const String deviceTypeSoilSensor = 'soil_sensor'; // Cảm biến độ ẩm đất
  static const String deviceTypeTempHumid = 'temp_humid';   // Cảm biến nhiệt độ/độ ẩm
  static const String deviceTypeLightSensor = 'light_sensor'; // Cảm biến ánh sáng
  static const String deviceTypeController = 'controller';   // Bộ điều khiển ESP32
  
  // Sensor Types
  static const String sensorTypeSoilMoisture = 'soil_moisture';     // Độ ẩm đất
  static const String sensorTypeTemperature = 'temperature';         // Nhiệt độ
  static const String sensorTypeHumidity = 'humidity';               // Độ ẩm không khí
  static const String sensorTypeLightIntensity = 'light_intensity'; // Cường độ ánh sáng
  static const String sensorTypeWaterLevel = 'water_level';          // Mực nước
  
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
