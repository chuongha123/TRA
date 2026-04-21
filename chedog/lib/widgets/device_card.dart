import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Device Card Widget - Card hiển thị thiết bị
class DeviceCard extends StatelessWidget {
  final String name;
  final String room;
  final String type;
  final bool isOn;
  final bool isOnline;
  final IconData icon;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.name,
    required this.room,
    required this.type,
    required this.isOn,
    required this.isOnline,
    required this.icon,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Device Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: isOn && isOnline
                      ? AppColors.primaryGradient
                      : LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[400]!],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isOn && isOnline ? Colors.white : Colors.grey[600],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Device Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.room_outlined,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            room,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOnline 
                                ? AppColors.deviceOnline 
                                : AppColors.deviceOffline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOnline 
                                ? AppColors.deviceOnline 
                                : AppColors.deviceOffline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Toggle Switch
              if (isOnline)
                Switch(
                  value: isOn,
                  onChanged: onToggle,
                  activeThumbColor: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
