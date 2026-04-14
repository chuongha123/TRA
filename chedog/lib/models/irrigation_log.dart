/// Irrigation Log Model - Lịch sử tưới nước
class IrrigationLog {
  final String id;
  final String deviceId;
  final String deviceName;
  final DateTime startTime;
  final DateTime? endTime;
  final double? flowAmount; // lít
  final String triggeredBy; // 'manual', 'schedule', 'auto'
  final String? scheduleName;
  final String zone; // khu vực

  IrrigationLog({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.startTime,
    this.endTime,
    this.flowAmount,
    required this.triggeredBy,
    this.scheduleName,
    required this.zone,
  });

  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;

  String get durationFormatted {
    if (duration == null) return 'Đang tưới...';
    final mins = duration!.inMinutes;
    final secs = duration!.inSeconds % 60;
    if (mins == 0) return '${secs}s';
    return '${mins}p ${secs}s';
  }

  String get triggeredByLabel {
    switch (triggeredBy) {
      case 'manual':
        return 'Thủ công';
      case 'schedule':
        return 'Lịch: ${scheduleName ?? ""}';
      case 'auto':
        return 'Tự động (cảm biến)';
      default:
        return triggeredBy;
    }
  }

  factory IrrigationLog.fromJson(Map<String, dynamic> json) {
    return IrrigationLog(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      flowAmount: json['flowAmount'] != null
          ? (json['flowAmount'] as num).toDouble()
          : null,
      triggeredBy: json['triggeredBy'] as String,
      scheduleName: json['scheduleName'] as String?,
      zone: json['zone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'flowAmount': flowAmount,
      'triggeredBy': triggeredBy,
      'scheduleName': scheduleName,
      'zone': zone,
    };
  }
}
