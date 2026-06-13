import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/sensor_data.dart';
import '../providers/sensor_provider.dart';
import 'sensor_history_screen.dart';
import 'irrigation_history_screen.dart';

/// Home Dashboard - Màn hình chính
class HomeDashboard extends StatefulWidget {
  final bool showBottomNav;

  const HomeDashboard({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,
    );
  }

  void _navigateByIndex(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
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
            builder: (_) =>
                const IrrigationHistoryScreen(showBackButton: false),
          ),
        );
        break;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào buổi sáng',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
          Text(
            'Nông trại thông minh',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        Consumer<SensorProvider>(
          builder: (_, sensor, _) => Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              if (sensor.unreadAlertCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${sensor.unreadAlertCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<SensorProvider>(
      builder: (context, sensor, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEnvironmentCard(sensor),
              const SizedBox(height: 16),
              _buildSystemModeToggle(sensor),
              const SizedBox(height: 16),
              _buildPumpButton(sensor),
              const SizedBox(height: 12),
              _buildDrainPumpButton(sensor),
              const SizedBox(height: 16),
              _buildChartsSection(sensor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemModeToggle(SensorProvider sensor) {
    final isAuto = sensor.isAutoMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Chế độ hệ thống',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          Container(
            height: 36,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (!isAuto) sensor.toggleSystemMode();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAuto ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Tự động',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isAuto ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (isAuto) sensor.toggleSystemMode();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: !isAuto ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Thủ công',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: !isAuto ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPumpButton(SensorProvider sensor) {
    final isOn = sensor.isPumpOn;
    final isToggling = sensor.isToggling;
    final error = sensor.pumpErrorMessage;
    final isActiveVisualState = isOn || isToggling;
    final foregroundColor = isActiveVisualState ? Colors.white : Colors.grey.shade900;
    final secondaryColor = isActiveVisualState ? Colors.white70 : Colors.grey.shade700;
    final iconBadgeColor = isActiveVisualState
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.8);
    
    return Column(
      children: [
        GestureDetector(
          onTap: (isToggling || sensor.isAutoMode) ? null : () => sensor.togglePump(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: isToggling
                  ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : (sensor.isAutoMode
                      ? LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : (isOn
                          ? AppColors.primaryGradient
                          : LinearGradient(
                              colors: [Colors.grey.shade300, Colors.grey.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ))),
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: (isOn ? (sensor.isAutoMode ? Colors.grey : AppColors.primary) : Colors.grey).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBadgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: isToggling
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(foregroundColor),
                          ),
                        )
                      : Icon(
                          isOn ? Icons.water_drop : Icons.water_drop_outlined,
                          color: foregroundColor,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToggling
                            ? 'Đang xử lý...'
                            : (isOn ? 'Máy bơm đang chạy' : 'Máy bơm đang tắt'),
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isToggling
                            ? 'Vui lòng chờ...'
                            : (sensor.isAutoMode
                                ? 'Tự động theo độ ẩm đất'
                                : (isOn ? 'Nhấn để TẮT bơm' : 'Nhấn để BẬT bơm')),
                        style: TextStyle(color: secondaryColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isToggling
                        ? Icons.hourglass_empty
                        : (isOn ? Icons.toggle_on_rounded : Icons.toggle_off_rounded),
                    key: ValueKey('${isToggling}_$isOn'),
                    color: foregroundColor,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => sensor.clearPumpError(),
                    child: Icon(Icons.close, color: Colors.red.shade700, size: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrainPumpButton(SensorProvider sensor) {
    final isOn = sensor.isDrainPumpOn;
    final isToggling = sensor.isTogglingDrain;
    final error = sensor.drainPumpErrorMessage;
    final isActiveVisualState = isOn || isToggling;
    final foregroundColor = isActiveVisualState ? Colors.white : Colors.grey.shade900;
    final secondaryColor = isActiveVisualState ? Colors.white70 : Colors.grey.shade700;
    final iconBadgeColor = isActiveVisualState
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.8);

    const drainColor = Color(0xFF00838F);
    const drainGradient = LinearGradient(
      colors: [Color(0xFF00838F), Color(0xFF006064)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Column(
      children: [
        GestureDetector(
          onTap: (isToggling || sensor.isAutoMode) ? null : () => sensor.toggleDrainPump(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: isToggling
                  ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : (sensor.isAutoMode
                      ? LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : (isOn
                          ? drainGradient
                          : LinearGradient(
                              colors: [Colors.grey.shade300, Colors.grey.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ))),
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: (isOn ? (sensor.isAutoMode ? Colors.grey : drainColor) : Colors.grey).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBadgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: isToggling
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(foregroundColor),
                          ),
                        )
                      : Icon(
                          isOn ? Icons.water : Icons.water_outlined,
                          color: foregroundColor,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToggling
                            ? 'Đang xử lý...'
                            : (isOn ? 'Bơm thoát đang chạy' : 'Bơm thoát đang tắt'),
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isToggling
                            ? 'Vui lòng chờ...'
                            : (sensor.isAutoMode
                                ? 'Tự động theo mực nước'
                                : (isOn ? 'Nhấn để TẮT bơm thoát' : 'Nhấn để BẬT bơm thoát')),
                        style: TextStyle(color: secondaryColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isToggling
                        ? Icons.hourglass_empty
                        : (isOn ? Icons.toggle_on_rounded : Icons.toggle_off_rounded),
                    key: ValueKey('drain_${isToggling}_$isOn'),
                    color: foregroundColor,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => sensor.clearDrainPumpError(),
                    child: Icon(Icons.close, color: Colors.red.shade700, size: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEnvironmentCard(SensorProvider sensor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vườn rau khu A',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.thermostat, color: Colors.white, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      '${sensor.temperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildEnvironmentInfo(
                        Icons.water_drop,
                        'Đất: ${sensor.soilMoisture.toStringAsFixed(1)}%',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildEnvironmentInfo(
                        Icons.air,
                        'KK: ${sensor.humidity.toStringAsFixed(1)}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildEnvironmentInfo(
                        Icons.speed,
                        'Áp suất: ${sensor.pressure.toStringAsFixed(0)} hPa',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildEnvironmentInfo(
                        Icons.waves,
                        'Nước: ${sensor.waterRaw.toStringAsFixed(1)}%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.wb_sunny,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection(SensorProvider sensor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Biểu đồ cảm biến',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _buildSensorChartCard(
          title: 'Độ ẩm đất',
          sensorType: 'soil_moisture',
          value: '${sensor.soilMoisture.toStringAsFixed(1)}%',
          icon: Icons.water_drop,
          color: const Color(0xFF1565C0),
          points: sensor.getHistoricalData('soil_moisture', '24h'),
        ),
        const SizedBox(height: 10),
        _buildSensorChartCard(
          title: 'Độ ẩm không khí',
          sensorType: 'humidity',
          value: '${sensor.humidity.toStringAsFixed(1)}%',
          icon: Icons.air,
          color: const Color(0xFF00838F),
          points: sensor.getHistoricalData('humidity', '24h'),
        ),
        const SizedBox(height: 10),
        _buildSensorChartCard(
          title: 'Nhiệt độ',
          sensorType: 'temperature',
          value: '${sensor.temperature.toStringAsFixed(1)}°C',
          icon: Icons.thermostat,
          color: const Color(0xFFE65100),
          points: sensor.getHistoricalData('temperature', '24h'),
        ),
        const SizedBox(height: 10),
        _buildSensorChartCard(
          title: 'Áp suất',
          sensorType: 'pressure',
          value: '${sensor.pressure.toStringAsFixed(0)} hPa',
          icon: Icons.compress,
          color: const Color(0xFF6A1B9A),
          points: sensor.getHistoricalData('pressure', '24h'),
        ),
        const SizedBox(height: 10),
        _buildSensorChartCard(
          title: 'Mực nước',
          sensorType: 'water_raw',
          value: '${sensor.waterRaw.toStringAsFixed(1)}%',
          icon: Icons.waves,
          color: const Color(0xFF00ACC1),
          points: sensor.getHistoricalData('water_raw', '24h'),
        ),
      ],
    );
  }

  Widget _buildSensorChartCard({
    required String title,
    required String sensorType,
    required String value,
    required IconData icon,
    required Color color,
    required List<ChartDataPoint> points,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SensorHistoryScreen(
                initialSensorType: sensorType,
                showBottomNav: false,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                height: 44,
                child: _buildMiniLineChart(points, color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniLineChart(List<ChartDataPoint> points, Color color) {
    if (points.isEmpty) {
      return const SizedBox();
    }

    final recent = points.length > 20 ? points.sublist(points.length - 20) : points;

    final start = recent.first.time;
    final spots = recent
        .map(
          (p) => FlSpot(
            p.time.difference(start).inMinutes.toDouble(),
            p.value,
          ),
        )
        .toList();

    final yValues = recent.map((e) => e.value).toList();
    final minY = yValues.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = yValues.reduce((a, b) => a > b ? a : b) + 1;
    final maxX = spots.last.x <= 0 ? 1.0 : spots.last.x;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
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
          icon: Icon(Icons.water_drop_outlined),
          activeIcon: Icon(Icons.water_drop),
          label: 'Lịch sử tưới',
        ),
      ],
    );
  }
}
