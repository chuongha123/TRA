import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/schedule_provider.dart';
import 'home_dashboard.dart';
import 'sensor_history_screen.dart';
import 'irrigation_history_screen.dart';

/// Schedule Screen - Lịch tưới nước (kiểu đặt giờ báo thức)
class ScheduleScreen extends StatefulWidget {
  final bool showBackButton;
  final bool showBottomNav;

  const ScheduleScreen({
    super.key,
    this.showBackButton = true,
    this.showBottomNav = true,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final int _selectedIndex = 2;

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
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const IrrigationHistoryScreen(showBackButton: false),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: const Text('Lịch tưới nước'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            onPressed: () => _showAddEditDialog(context, null),
          ),
        ],
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          if (provider.schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Chưa có lịch tưới nào',
                      style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm lịch tưới'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: provider.schedules.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final schedule = provider.schedules[index];
              return _buildAlarmCard(context, provider, schedule);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Thêm lịch'),
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

  Widget _buildAlarmCard(BuildContext context, ScheduleProvider provider,
      IrrigationSchedule schedule) {
    return Dismissible(
      key: Key(schedule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        provider.deleteSchedule(schedule.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${schedule.name}"'),
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () => provider.addSchedule(schedule),
            ),
          ),
        );
      },
      child: Card(
        elevation: schedule.isEnabled ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          side: BorderSide(
            color: schedule.isEnabled
                ? AppColors.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          onTap: () => _showAddEditDialog(context, schedule),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // --- Hiển thị giờ kiểu đồng hồ báo thức ---
                    Text(
                      schedule.timeLabel,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        color: schedule.isEnabled
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Colors.grey,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Switch.adaptive(
                      value: schedule.isEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (_) => provider.toggleSchedule(schedule.id),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.label_outline,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      schedule.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: schedule.isEnabled ? null : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _chip(Icons.repeat, schedule.daysLabel,
                        schedule.isEnabled),
                    const SizedBox(width: 8),
                    _chip(Icons.timer_outlined,
                        '${schedule.durationMinutes} phút', schedule.isEnabled),
                    const SizedBox(width: 8),
                    _chip(Icons.grass, schedule.zone, schedule.isEnabled),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled
            ? AppColors.primary.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: isEnabled ? AppColors.primary : Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isEnabled ? AppColors.primary : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Thêm / Sửa lịch ─────────────────────────────────────────────────────
  void _showAddEditDialog(
      BuildContext context, IrrigationSchedule? existing) {
    final provider = context.read<ScheduleProvider>();
    final isEdit = existing != null;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    TimeOfDay selectedTime =
        existing?.time ?? const TimeOfDay(hour: 6, minute: 0);
    List<bool> selectedDays =
        existing?.days != null ? List.from(existing!.days) : List.filled(7, true);
    int duration = existing?.durationMinutes ?? 15;
    String zone = existing?.zone ?? AppConstants.availableZones.first;

    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final zones = AppConstants.availableZones;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Chỉnh sửa lịch tưới' : 'Thêm lịch tưới mới',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),

                // --- Tên lịch ---
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên lịch',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Chọn giờ ---
                const Text('Giờ tưới',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                      builder: (c, child) => MediaQuery(
                        data: MediaQuery.of(c)
                            .copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setModalState(() => selectedTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_alarm,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Ngày lặp ---
                const Text('Lặp lại',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final active = selectedDays[i];
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedDays[i] = !selectedDays[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? AppColors.primary
                              : Colors.grey.withOpacity(0.15),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          dayLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // --- Thời lượng ---
                Row(
                  children: [
                    const Text('Thời lượng:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('$duration phút',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
                Slider(
                  value: duration.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  activeColor: AppColors.primary,
                  label: '$duration phút',
                  onChanged: (v) => setModalState(() => duration = v.round()),
                ),
                const SizedBox(height: 8),

                // --- Khu vực ---
                DropdownButtonFormField<String>(
                  initialValue: zone,
                  decoration: const InputDecoration(
                    labelText: 'Khu vực',
                    prefixIcon: Icon(Icons.grass),
                  ),
                  items: zones
                      .map((z) =>
                          DropdownMenuItem(value: z, child: Text(z)))
                      .toList(),
                  onChanged: (v) => setModalState(() => zone = v!),
                ),
                const SizedBox(height: 24),

                // --- Nút lưu ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Vui lòng nhập tên lịch')));
                        return;
                      }
                      final s = IrrigationSchedule(
                        id: existing?.id ?? provider.generateId(),
                        name: nameCtrl.text.trim(),
                        time: selectedTime,
                        days: selectedDays,
                        durationMinutes: duration,
                        zone: zone,
                        isEnabled: existing?.isEnabled ?? true,
                      );
                      if (isEdit) {
                        provider.updateSchedule(s);
                      } else {
                        provider.addSchedule(s);
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isEdit ? 'Lưu thay đổi' : 'Thêm lịch tưới'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
