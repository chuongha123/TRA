/// Sensor Data Model - Dữ liệu cảm biến
class SensorData {
  final String id;
  final String deviceId;
  final String sensorType; // temperature, humidity, motion, door, energy
  final double value;
  final String unit;
  final DateTime timestamp;
  
  SensorData({
    required this.id,
    required this.deviceId,
    required this.sensorType,
    required this.value,
    required this.unit,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  // Constructor từ JSON
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      sensorType: json['sensorType'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
  
  // Chuyển đổi sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'sensorType': sensorType,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  // Copy with method
  SensorData copyWith({
    String? id,
    String? deviceId,
    String? sensorType,
    double? value,
    String? unit,
    DateTime? timestamp,
  }) {
    return SensorData(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      sensorType: sensorType ?? this.sensorType,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  // Lấy giá trị đã format
  String get formattedValue {
    return '${value.toStringAsFixed(1)} $unit';
  }
}

/// Chart Data Point - Điểm dữ liệu cho biểu đồ
class ChartDataPoint {
  final DateTime time;
  final double value;
  
  ChartDataPoint({
    required this.time,
    required this.value,
  });
}
