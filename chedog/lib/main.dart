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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProxyProvider<SensorProvider, ScheduleProvider>(
          create: (context) => ScheduleProvider(context.read<SensorProvider>()),
          update: (context, sensorProvider, scheduleProvider) {
            scheduleProvider?.updateSensorProvider(sensorProvider);
            return scheduleProvider ?? ScheduleProvider(sensorProvider);
          },
        ),
      ],
      child: const _AppLifecycleBridge(),
    );
  }
}

class _AppLifecycleBridge extends StatefulWidget {
  const _AppLifecycleBridge();

  @override
  State<_AppLifecycleBridge> createState() => _AppLifecycleBridgeState();
}

class _AppLifecycleBridgeState extends State<_AppLifecycleBridge>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<SensorProvider>().onAppResumed();
      context.read<ScheduleProvider>().onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Smart Agriculture IoT',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
    );
  }
}
