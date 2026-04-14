import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/sensor_data.dart';
import '../providers/sensor_provider.dart';
import 'home_dashboard.dart';
import 'schedule_screen.dart';
import 'irrigation_history_screen.dart';

/// Sensor History Screen - Xem lại lịch sử dữ liệu cảm biến
class SensorHistoryScreen extends StatefulWidget {
  final String? initialSensorType;
  final bool showBackButton;
  final bool showBottomNav;

  const SensorHistoryScreen({
    super.key,
    this.initialSensorType,
    this.showBackButton = true,
    this.showBottomNav = true,
  });

  @override
  State<SensorHistoryScreen> createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends State<SensorHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 1;
  String _selectedPeriod = '24h';

  static const _sensorTypes = [
    'soil_moisture',
    'humidity',
    'temperature',
    'pressure',
  ];
  static const _sensorLabels = {
    'soil_moisture': 'Độ ẩm đất',
    'humidity': 'Độ ẩm KK',
    'temperature': 'Nhiệt độ',
    'pressure': 'Áp suất',
  };
  static const _sensorTabLabels = {
    'soil_moisture': 'Đất',
    'humidity': 'KK',
    'temperature': 'Nhiệt',
    'pressure': 'Áp suất',
  };
  static const _sensorUnits = {
    'soil_moisture': '%',
    'humidity': '%',
    'temperature': '°C',
    'pressure': 'hPa',
  };
  static const _sensorColors = {
    'soil_moisture': Color(0xFF1565C0),
    'humidity': Color(0xFF00838F),
    'temperature': Color(0xFFE65100),
    'pressure': Color(0xFF6A1B9A),
  };
  static const _sensorIcons = {
    'soil_moisture': Icons.water_drop,
    'humidity': Icons.air,
    'temperature': Icons.thermostat,
    'pressure': Icons.compress,
  };
  static const _sensorMinY = {
    'soil_moisture': 0.0,
    'humidity': 0.0,
    'temperature': 10.0,
    'pressure': 990.0,
  };
  static const _sensorMaxY = {
    'soil_moisture': 100.0,
    'humidity': 100.0,
    'temperature': 45.0,
    'pressure': 1035.0,
  };

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialSensorType != null
        ? _sensorTypes.indexOf(widget.initialSensorType!)
        : 0;
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        title: const Text('Lịch sử cảm biến'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: _sensorTypes
              .map((t) => Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_sensorIcons[t], size: 13),
                          const SizedBox(width: 3),
                          Text(_sensorTabLabels[t]!),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          _buildPeriodBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _sensorTypes
                  .map((type) => _buildHistoryTab(type))
                  .toList(),
            ),
          ),
        ],
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

  Widget _buildPeriodBar() {
    const periods = ['6h', '24h', '7d', '30d'];
    const labels = {'6h': '6 giờ', '24h': '24 giờ', '7d': '7 ngày', '30d': '30 ngày'};
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: periods.map((p) {
          final sel = _selectedPeriod == p;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: OutlinedButton(
                onPressed: () => setState(() => _selectedPeriod = p),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      sel ? AppColors.primary : Colors.transparent,
                  foregroundColor:
                      sel ? Colors.white : AppColors.primary,
                  side: BorderSide(
                    color:
                        sel ? AppColors.primary : Colors.grey.shade400,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(labels[p]!, style: const TextStyle(fontSize: 12)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryTab(String type) {
    return Consumer<SensorProvider>(
      builder: (context, sensor, _) {
        final data = sensor.getHistoricalData(type, _selectedPeriod);
        final color = _sensorColors[type]!;
        final unit = _sensorUnits[type]!;
        final minY = _sensorMinY[type]!;
        final maxY = _sensorMaxY[type]!;

        if (data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Tính thống kê
        final values = data.map((p) => p.value).toList();
        final avg = values.reduce((a, b) => a + b) / values.length;
        final minVal = values.reduce((a, b) => a < b ? a : b);
        final maxVal = values.reduce((a, b) => a > b ? a : b);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thẻ thống kê
              Row(
                children: [
                  _statCard('Trung bình', '${avg.toStringAsFixed(1)} $unit',
                      color, Icons.show_chart),
                  const SizedBox(width: 8),
                  _statCard('Thấp nhất', '${minVal.toStringAsFixed(1)} $unit',
                      Colors.blue, Icons.arrow_downward),
                  const SizedBox(width: 8),
                  _statCard('Cao nhất', '${maxVal.toStringAsFixed(1)} $unit',
                      Colors.red, Icons.arrow_upward),
                ],
              ),
              const SizedBox(height: 16),

              // Biểu đồ lớn
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusLarge),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sensorLabels[type]!,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: _buildChart(data, color, minY, maxY, unit),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bảng dữ liệu
              Text('Dữ liệu chi tiết',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildDataTable(data, color, unit, sensor.thresholds[type]),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<ChartDataPoint> data, Color color, double minY,
      double maxY, String unit) {
    if (data.isEmpty) return const SizedBox();
    final startTime = data.first.time;
    final spots = data
        .map((p) => FlSpot(
            p.time.difference(startTime).inMinutes.toDouble(), p.value))
        .toList();
    final totalMinutes =
        data.last.time.difference(startTime).inMinutes.toDouble();

    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 4,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: (maxY - minY) / 4,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(v.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.right),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: totalMinutes / 4,
            getTitlesWidget: (value, _) {
              final t =
                  startTime.add(Duration(minutes: value.round()));
              final label =
                  (_selectedPeriod == '7d' || _selectedPeriod == '30d')
                      ? '${t.day}/${t.month}'
                      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(label,
                    style:
                        const TextStyle(fontSize: 9, color: Colors.grey)),
              );
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
          left: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
      minX: 0,
      maxX: totalMinutes,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((spot) {
            final t =
                startTime.add(Duration(minutes: spot.x.round()));
            return LineTooltipItem(
              '${spot.y.toStringAsFixed(1)} $unit\n',
              TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              children: [
                TextSpan(
                  text: DateFormat('HH:mm dd/MM').format(t),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ));
  }

  Widget _buildDataTable(
      List<ChartDataPoint> data, Color color, String unit, double? threshold) {
    // Hiển thị 20 điểm gần nhất
    final recent = data.reversed.take(20).toList();
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Text('Thời gian',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12))),
                Expanded(
                    child: Text('Giá trị',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12))),
                Expanded(
                    child: Text('Trạng thái',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12))),
              ],
            ),
          ),
          const Divider(height: 1),
          ...recent.asMap().entries.map((entry) {
            final idx = entry.key;
            final point = entry.value;
            final isAnomaly = threshold != null && point.value < threshold;
            return Container(
              color: idx.isEven
                  ? null
                  : Theme.of(context).dividerColor.withOpacity(0.05),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        DateFormat('HH:mm dd/MM').format(point.time),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${point.value.toStringAsFixed(1)} $unit',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAnomaly ? AppColors.error : color,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: isAnomaly
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Bất thường',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold)),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Bình thường',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold)),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
