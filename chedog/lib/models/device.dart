/// Device Model - Mô hình thiết bị IoT
class Device {
  final String id;
  final String name;
  final String type; // light, switch, fan, ac, door, sensor
  final String room;
  final bool isOnline;
  final bool isOn;
  final String iconName;
  final Map<String, dynamic>? properties; // Các thuộc tính đặc biệt của thiết bị
  final DateTime lastUpdated;
  
  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.room,
    this.isOnline = true,
    this.isOn = false,
    this.iconName = 'device',
    this.properties,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  
  // Constructor từ JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      room: json['room'] as String,
      isOnline: json['isOnline'] as bool? ?? true,
      isOn: json['isOn'] as bool? ?? false,
      iconName: json['iconName'] as String? ?? 'device',
      properties: json['properties'] as Map<String, dynamic>?,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }
  
  // Chuyển đổi sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'room': room,
      'isOnline': isOnline,
      'isOn': isOn,
      'iconName': iconName,
      'properties': properties,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  // Copy with method
  Device copyWith({
    String? id,
    String? name,
    String? type,
    String? room,
    bool? isOnline,
    bool? isOn,
    String? iconName,
    Map<String, dynamic>? properties,
    DateTime? lastUpdated,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      room: room ?? this.room,
      isOnline: isOnline ?? this.isOnline,
      isOn: isOn ?? this.isOn,
      iconName: iconName ?? this.iconName,
      properties: properties ?? this.properties,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  // Lấy giá trị thuộc tính đặc biệt
  dynamic getProperty(String key) {
    return properties?[key];
  }
  
  // Mô tả trạng thái
  String get statusDescription {
    if (!isOnline) return 'Offline';
    if (isOn) return 'On';
    return 'Off';
  }
}
