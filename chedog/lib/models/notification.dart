/// Notification Model - Thông báo và cảnh báo
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // info, warning, error, success
  final String? deviceId;
  final DateTime timestamp;
  final bool isRead;
  
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.deviceId,
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();
  
  // Constructor từ JSON
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      deviceId: json['deviceId'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
  
  // Chuyển đổi sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'deviceId': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
  
  // Copy with method
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? deviceId,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
  
  // Lấy thời gian hiển thị
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
