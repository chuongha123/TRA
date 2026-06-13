import 'dart:async';

import 'background_schedule_service.dart';
import 'notification_service.dart';

/// Heavy platform setup deferred until after the first frame to avoid ANR on cold start.
Future<void> initializeAppServices() async {
  try {
    await NotificationService()
        .initialize()
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    // Notifications are optional at startup.
  }

  try {
    await BackgroundScheduleService.initialize().timeout(
      const Duration(seconds: 8),
    );
  } catch (_) {
    // Native alarm sync can be retried when schedules change.
  }
}
