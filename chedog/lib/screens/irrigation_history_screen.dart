import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/irrigation_log.dart';
import '../providers/sensor_provider.dart';
import 'home_dashboard.dart';
import 'sensor_history_screen.dart';
import 'schedule_screen.dart';

/// Irrigation History Screen - Lịch sử tưới nước
class IrrigationHistoryScreen extends StatefulWidget {
  final bool showBackButton;
  final bool showBottomNav;

  const IrrigationHistoryScreen({
    super.key,
    this.showBackButton = true,
    this.showBottomNav = true,
  });

  @override
  State<IrrigationHistoryScreen> createState() =>
      _IrrigationHistoryScreenState();
}

class _IrrigationHistoryScreenState extends State<IrrigationHistoryScreen> {
  final int _selectedIndex = 3;
  String _filterBy = 'all'; // 'all', 'manual', 'schedule', 'auto'

  void _navigateByIndex(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeDashboard()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SensorHistoryScreen(showBackButton: false),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ScheduleScreen(showBackButton: false),
          ),
        );
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: const Text('Lịch sử tưới nước'),
        actions: [
          Consumer<SensorProvider>(
            builder: (_, sensor, _) => sensor.irrigationLogs.isNotEmpty
                ? IconButton(
                    tooltip: 'Xóa toàn bộ lịch sử',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => _confirmDeleteAll(context, sensor),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, sensor, _) {
          final logs = sensor.irrigationLogs
              .where((l) => _filterBy == 'all' || l.triggeredBy == _filterBy)
              .toList();

          // Tổng hợp thống kê
          final now = DateTime.now();
          final totalLogs = sensor.irrigationLogs.length;
          final totalIrrigationMinutes = sensor.irrigationLogs.fold<int>(
            0,
            (sum, l) =>
                sum + (l.endTime ?? now).difference(l.startTime).inMinutes,
          );
          final last7DaysThreshold = now.subtract(const Duration(days: 7));
          final last7DaysMinutes = sensor.irrigationLogs
              .where((l) => l.startTime.isAfter(last7DaysThreshold))
              .fold<int>(
                0,
                (sum, l) =>
                    sum + (l.endTime ?? now).difference(l.startTime).inMinutes,
              );

          return Column(
            children: [
              // Thẻ thống kê tổng
              _buildSummaryCard(
                totalLogs,
                totalIrrigationMinutes,
                last7DaysMinutes,
              ),

              // Bộ lọc
              _buildFilterBar(),

              // Danh sách
              Expanded(
                child: logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.water_drop_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Không có dữ liệu',
                                style:
                                    TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        itemCount: logs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildDismissibleLogCard(context, sensor, logs[index]),
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                _navigateByIndex(index);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sensors_outlined),
                  activeIcon: Icon(Icons.sensors),
                  label: 'Cảm biến',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.schedule_outlined),
                  activeIcon: Icon(Icons.schedule),
                  label: 'Lịch tưới',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.water_drop_outlined),
                  activeIcon: Icon(Icons.water_drop),
                  label: 'Lịch sử tưới',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildSummaryCard(
      int totalLogs, int totalIrrigationMinutes, int last7DaysMinutes) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryItem(
            icon: Icons.format_list_bulleted,
            label: 'Tổng lần tưới',
            value: '$totalLogs lần',
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          _summaryItem(
            icon: Icons.timelapse,
            label: 'Tổng thời gian tưới',
            value: _formatDurationFromMinutes(totalIrrigationMinutes),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          _summaryItem(
            icon: Icons.calendar_month,
            label: '7 ngày qua',
            value: _formatDurationFromMinutes(last7DaysMinutes),
          ),
        ],
      ),
    );
  }

  String _formatDurationFromMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return '0p';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}p';
    if (minutes == 0) return '${hours}g';
    return '${hours}g ${minutes}p';
  }

  Widget _summaryItem(
      {required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    const filters = {
      'all': 'Tất cả',
      'manual': 'Thủ công',
      'schedule': 'Lịch trình',
      'auto': 'Tự động',
    };
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.entries.map((e) {
          final selected = _filterBy == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _filterBy = e.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, IrrigationLog log) {
    final isActive = log.endTime == null;
    Color triggerColor;
    IconData triggerIcon;
    switch (log.triggeredBy) {
      case 'manual':
        triggerColor = AppColors.info;
        triggerIcon = Icons.touch_app;
        break;
      case 'schedule':
        triggerColor = AppColors.primary;
        triggerIcon = Icons.schedule;
        break;
      default:
        triggerColor = AppColors.warning;
        triggerIcon = Icons.sensors;
    }

    return Card(
      elevation: isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        side: isActive
            ? BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot
            Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : triggerColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.water_drop : triggerIcon,
                    color: isActive ? Colors.white : triggerColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.deviceName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 6),
                              SizedBox(width: 4),
                              Text('Đang tưới',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Thông tin chi tiết
                  Row(
                    children: [
                      Icon(Icons.grass,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(log.zone,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Thời gian bắt đầu
                  Row(
                    children: [
                      Icon(triggerIcon, size: 13, color: triggerColor),
                      const SizedBox(width: 4),
                      Text(
                        log.triggeredByLabel,
                        style: TextStyle(
                            fontSize: 12,
                            color: triggerColor,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Expanded(
                        child: _infoChip(
                          Icons.play_circle_outline,
                          'Bắt đầu: ${DateFormat('HH:mm dd/MM').format(log.startTime)}',
                        ),
                      ),
                    ],
                  ),
                  if (log.endTime != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _infoChip(Icons.timer_outlined,
                            log.durationFormatted),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleLogCard(
    BuildContext context,
    SensorProvider sensor,
    IrrigationLog log,
  ) {
    final isActive = log.endTime == null;
    if (isActive) {
      return _buildLogCard(context, log);
    }

    return Dismissible(
      key: ValueKey('irrigation_${log.id}'),
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
        sensor.deleteIrrigationSession(log.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lịch sử tưới')),
        );
      },
      child: _buildLogCard(context, log),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, SensorProvider sensor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ lịch sử tưới?'),
        content: const Text('Tất cả lịch sử tưới sẽ bị xóa khỏi ứng dụng và cơ sở dữ liệu.'),
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

    sensor.deleteAllIrrigationSessions();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa toàn bộ lịch sử tưới')),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
