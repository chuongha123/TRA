/// Schedule Model - Lịch trình tự động
class Schedule {
  final String id;
  final String name;
  final String deviceId;
  final String action; // on, off, set_value
  final Map<String, dynamic>? actionParams;
  final String scheduleType; // once, daily, weekly
  final DateTime? scheduleTime;
  final List<int>? daysOfWeek; // 0-6 (Sunday-Saturday)
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? lastRun;
  
  Schedule({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.action,
    this.actionParams,
    required this.scheduleType,
    this.scheduleTime,
    this.daysOfWeek,
    this.isEnabled = true,
    DateTime? createdAt,
    this.lastRun,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Constructor từ JSON
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      name: json['name'] as String,
      deviceId: json['deviceId'] as String,
      action: json['action'] as String,
      actionParams: json['actionParams'] as Map<String, dynamic>?,
      scheduleType: json['scheduleType'] as String,
      scheduleTime: json['scheduleTime'] != null
          ? DateTime.parse(json['scheduleTime'] as String)
          : null,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'] as List)
          : null,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastRun: json['lastRun'] != null
          ? DateTime.parse(json['lastRun'] as String)
          : null,
    );
  }
  
  // Chuyển đổi sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deviceId': deviceId,
      'action': action,
      'actionParams': actionParams,
      'scheduleType': scheduleType,
      'scheduleTime': scheduleTime?.toIso8601String(),
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'lastRun': lastRun?.toIso8601String(),
    };
  }
  
  // Copy with method
  Schedule copyWith({
    String? id,
    String? name,
    String? deviceId,
    String? action,
    Map<String, dynamic>? actionParams,
    String? scheduleType,
    DateTime? scheduleTime,
    List<int>? daysOfWeek,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? lastRun,
  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      action: action ?? this.action,
      actionParams: actionParams ?? this.actionParams,
      scheduleType: scheduleType ?? this.scheduleType,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastRun: lastRun ?? this.lastRun,
    );
  }
  
  // Lấy mô tả lịch trình
  String get scheduleDescription {
    if (scheduleType == 'once') {
      return 'Once at ${_formatTime(scheduleTime!)}';
    } else if (scheduleType == 'daily') {
      return 'Every day at ${_formatTime(scheduleTime!)}';
    } else if (scheduleType == 'weekly' && daysOfWeek != null) {
      final days = daysOfWeek!.map((d) => _getDayName(d)).join(', ');
      return '$days at ${_formatTime(scheduleTime!)}';
    }
    return 'Unknown schedule';
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  String _getDayName(int day) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[day];
  }
}
