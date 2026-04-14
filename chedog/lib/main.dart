import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/schedule_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_tab_screen.dart';
import 'screens/device_detail_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sensor_history_screen.dart';
import 'screens/irrigation_history_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Smart Agriculture IoT',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode 
                ? ThemeMode.dark 
                : ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const MainTabScreen(),
              '/device-detail': (context) => const DeviceDetailScreen(),
              '/schedule': (context) => const ScheduleScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
              '/notifications': (context) => const NotificationScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/sensor-history': (context) => const SensorHistoryScreen(),
              '/irrigation-history': (context) => const IrrigationHistoryScreen(),
            },
          );
        },
      ),
    );
  }
}
