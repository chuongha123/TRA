import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/sensor_provider.dart';

/// Notification Screen - Thông báo cảnh báo bất thường
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cảnh báo & Ngưỡng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_active), text: 'Cảnh báo'),
            Tab(icon: Icon(Icons.tune), text: 'Cài ngưỡng'),
          ],
        ),
        actions: [
          Consumer<SensorProvider>(
            builder: (_, sensor, _) => sensor.unreadAlertCount > 0
                ? TextButton.icon(
                    onPressed: () => sensor.markAllAlertsRead(),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Đọc tất cả', style: TextStyle(fontSize: 12)),
                  )
                : const SizedBox.shrink(),
          ),
          Consumer<SensorProvider>(
            builder: (_, sensor, _) => sensor.alerts.isNotEmpty
                ? IconButton(
                    tooltip: 'Xóa toàn bộ lịch sử',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => _confirmDeleteAll(context, sensor),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsTab(),
          _buildThresholdTab(),
        ],
      ),
    );
  }

  // ─────────────── Tab Cảnh báo ───────────────────────────────────────────
  Widget _buildAlertsTab() {
    return Consumer<SensorProvider>(
      builder: (context, sensor, _) {
        final alerts = sensor.alerts;
        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 72, color: AppColors.success),
                const SizedBox(height: 16),
                const Text('Không có cảnh báo nào',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Tất cả thông số trong mức an toàn',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        // Nhóm đọc/chưa đọc
        final unread = alerts.where((a) => !(a['isRead'] as bool)).toList();
        final read = alerts.where((a) => a['isRead'] as bool).toList();

        return ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            if (unread.isNotEmpty) ...[
              _sectionHeader('Chưa đọc (${unread.length})', AppColors.error),
              const SizedBox(height: 8),
              ...unread.map((a) => _buildDismissibleAlertCard(context, sensor, a)),
              const SizedBox(height: 16),
            ],
            if (read.isNotEmpty) ...[
              _sectionHeader('Đã đọc', Colors.grey),
              const SizedBox(height: 8),
              ...read.map((a) => _buildDismissibleAlertCard(context, sensor, a)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDismissibleAlertCard(
    BuildContext context,
    SensorProvider sensor,
    Map<String, dynamic> alert,
  ) {
    final alertId = (alert['id'] ?? '').toString();
    if (alertId.isEmpty) {
      return _buildAlertCard(context, sensor, alert);
    }

    return Dismissible(
      key: ValueKey('alert_$alertId'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        sensor.deleteAlert(alertId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa cảnh báo')),
        );
      },
      child: _buildAlertCard(context, sensor, alert),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13)),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, SensorProvider sensor,
      Map<String, dynamic> alert) {
    final isRead = alert['isRead'] as bool;
    final type = alert['type'] as String;
    final timestamp = alert['timestamp'] as DateTime;

    Color typeColor;
    IconData typeIcon;
    switch (type) {
      case 'soil_moisture':
        typeColor = const Color(0xFF1565C0);
        typeIcon = Icons.water_drop;
        break;
      case 'weather_rain_warning':
        typeColor = const Color(0xFF2E7D32);
        typeIcon = Icons.cloudy_snowing;
        break;
      case 'humidity':
        typeColor = const Color(0xFF00838F);
        typeIcon = Icons.air;
        break;
      case 'temperature':
        typeColor = const Color(0xFFE65100);
        typeIcon = Icons.thermostat;
        break;
      default:
        typeColor = const Color(0xFF6A1B9A);
        typeIcon = Icons.compress;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: isRead ? 1 : 3,
        color: isRead
            ? null
            : AppColors.error.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          side: BorderSide(
            color: isRead ? Colors.transparent : AppColors.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isRead ? typeColor : AppColors.error).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRead ? typeIcon : Icons.warning_amber_rounded,
              color: isRead ? typeColor : AppColors.error,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  alert['title'] as String,
                  style: TextStyle(
                    fontWeight:
                        isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(alert['message'] as String,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(alert['zone'] as String,
                      style: const TextStyle(fontSize: 11)),
                  const Spacer(),
                  Icon(Icons.access_time,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(
                    _timeAgo(timestamp),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            if (!isRead) sensor.markAlertRead(alert['id'] as String);
          },
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  Future<void> _confirmDeleteAll(BuildContext context, SensorProvider sensor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ lịch sử?'),
        content: const Text('Tất cả cảnh báo sẽ bị xóa khỏi ứng dụng và cơ sở dữ liệu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    sensor.deleteAllAlerts();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa toàn bộ lịch sử cảnh báo')),
    );
  }

  // ─────────────── Tab Cài ngưỡng ──────────────────────────────────────────
  Widget _buildThresholdTab() {
    return Consumer<SensorProvider>(
      builder: (context, sensor, _) {
        return ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusLarge),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cài đặt ngưỡng cảnh báo',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ứng dụng sẽ gửi cảnh báo khi thông số vượt ngưỡng',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildThresholdCard(
              context: context,
              sensor: sensor,
              type: 'soil_moisture',
              label: 'Độ ẩm đất',
              icon: Icons.water_drop,
              color: const Color(0xFF1565C0),
              unit: '%',
              alertType: 'below',
              min: 10,
              max: 60,
              divisions: 50,
              description: 'Cảnh báo khi độ ẩm đất thấp hơn ngưỡng',
            ),
            const SizedBox(height: 12),
            _buildThresholdCard(
              context: context,
              sensor: sensor,
              type: 'humidity',
              label: 'Độ ẩm không khí',
              icon: Icons.air,
              color: const Color(0xFF00838F),
              unit: '%',
              alertType: 'below',
              min: 20,
              max: 70,
              divisions: 50,
              description: 'Cảnh báo khi độ ẩm không khí thấp hơn ngưỡng',
            ),
            const SizedBox(height: 12),
            _buildThresholdCard(
              context: context,
              sensor: sensor,
              type: 'temperature',
              label: 'Nhiệt độ',
              icon: Icons.thermostat,
              color: const Color(0xFFE65100),
              unit: '°C',
              alertType: 'above',
              min: 25,
              max: 50,
              divisions: 25,
              description: 'Cảnh báo khi nhiệt độ cao hơn ngưỡng',
            ),
            const SizedBox(height: 12),
            _buildThresholdCard(
              context: context,
              sensor: sensor,
              type: 'pressure',
              label: 'Áp suất khí quyển',
              icon: Icons.compress,
              color: const Color(0xFF6A1B9A),
              unit: 'hPa',
              alertType: 'below',
              min: 990,
              max: 1015,
              divisions: 25,
              description: 'Cảnh báo khi áp suất thấp hơn ngưỡng',
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildThresholdCard({
    required BuildContext context,
    required SensorProvider sensor,
    required String type,
    required String label,
    required IconData icon,
    required Color color,
    required String unit,
    required String alertType, // 'below' | 'above'
    required double min,
    required double max,
    required int divisions,
    required String description,
  }) {
    final current = sensor.thresholds[type] ?? (alertType == 'below' ? 30.0 : 38.0);
    final currentSensorValue = sensor.currentReadings[type] ?? 0;
    final isAlerting = alertType == 'below'
        ? currentSensorValue < current
        : currentSensorValue > current;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        side: isAlerting
            ? BorderSide(color: AppColors.error.withOpacity(0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(description,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (isAlerting)
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  alertType == 'below' ? 'Ngưỡng thấp tối thiểu:' : 'Ngưỡng cao tối đa:',
                  style: const TextStyle(fontSize: 13),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${current.toStringAsFixed(alertType == 'pressure' ? 0 : 1)} $unit',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ],
            ),
            Slider(
              value: current.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              activeColor: color,
              inactiveColor: color.withOpacity(0.2),
              label: '${current.toStringAsFixed(0)} $unit',
              onChanged: (v) => sensor.updateThreshold(type, v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$min $unit',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                Row(
                  children: [
                    Text('Hiện tại: ',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    Text(
                      '${currentSensorValue.toStringAsFixed(1)} $unit',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAlerting ? AppColors.error : color),
                    ),
                  ],
                ),
                Text('$max $unit',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
