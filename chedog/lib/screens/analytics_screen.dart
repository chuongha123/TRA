import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/sensor_data.dart';
import '../providers/sensor_provider.dart';

/// Analytics Screen - 4 biểu đồ theo dõi cảm biến
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = '24h';

  static const _periods = ['6h', '24h', '7d', '30d'];
  static const _periodLabels = {
    '6h': '6 giờ',
    '24h': '24 giờ',
    '7d': '7 ngày',
    '30d': '30 ngày',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biểu đồ cảm biến'),
      ),
      body: Consumer<SensorProvider>(
        builder: (context, sensor, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 20),
                _buildCurrentValues(sensor),
                const SizedBox(height: 20),
                _buildChartCard(
                  title: 'Độ ẩm đất',
                  unit: '%',
                  color: const Color(0xFF1565C0),
                  data: sensor.getHistoricalData('soil_moisture', _selectedPeriod),
                  minY: 0,
                  maxY: 100,
                  icon: Icons.water_drop,
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  title: 'Độ ẩm không khí',
                  unit: '%',
                  color: const Color(0xFF00838F),
                  data: sensor.getHistoricalData('humidity', _selectedPeriod),
                  minY: 0,
                  maxY: 100,
                  icon: Icons.air,
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  title: 'Nhiệt độ',
                  unit: '°C',
                  color: const Color(0xFFE65100),
                  data: sensor.getHistoricalData('temperature', _selectedPeriod),
                  minY: 10,
                  maxY: 45,
                  icon: Icons.thermostat,
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  title: 'Áp suất khí quyển',
                  unit: 'hPa',
                  color: const Color(0xFF6A1B9A),
                  data: sensor.getHistoricalData('pressure', _selectedPeriod),
                  minY: 990,
                  maxY: 1035,
                  icon: Icons.compress,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: _periods.map((p) {
            final isSelected = _selectedPeriod == p;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ElevatedButton(
                  onPressed: () => setState(() => _selectedPeriod = p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                    foregroundColor: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    elevation: isSelected ? 2 : 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shadowColor: Colors.transparent,
                  ),
                  child: Text(_periodLabels[p]!, style: const TextStyle(fontSize: 12)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCurrentValues(SensorProvider sensor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildValueTile('Độ ẩm đất', '${sensor.soilMoisture.toStringAsFixed(1)}%',
            Icons.water_drop, const Color(0xFF1565C0),
            sensor.soilMoisture < sensor.thresholds['soil_moisture']!),
        _buildValueTile('Độ ẩm KK', '${sensor.humidity.toStringAsFixed(1)}%',
            Icons.air, const Color(0xFF00838F),
            sensor.humidity < sensor.thresholds['humidity']!),
        _buildValueTile('Nhiệt độ', '${sensor.temperature.toStringAsFixed(1)}°C',
            Icons.thermostat, const Color(0xFFE65100),
            sensor.temperature > sensor.thresholds['temperature']!),
        _buildValueTile('Áp suất', '${sensor.pressure.toStringAsFixed(0)} hPa',
            Icons.compress, const Color(0xFF6A1B9A),
            sensor.pressure < sensor.thresholds['pressure']!),
      ],
    );
  }

  Widget _buildValueTile(
      String label, String value, IconData icon, Color color, bool isAlert) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.warning.withOpacity(0.1) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isAlert ? AppColors.warning : color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isAlert ? AppColors.warning : color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color)),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isAlert ? AppColors.warning : color)),
              ],
            ),
          ),
          if (isAlert)
            const Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String unit,
    required Color color,
    required List<ChartDataPoint> data,
    required double minY,
    required double maxY,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
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
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (data.isNotEmpty)
                  Text('${data.last.value.toStringAsFixed(1)} $unit',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: data.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLineChart(data, color, minY, maxY, unit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<ChartDataPoint> data, Color color, double minY,
      double maxY, String unit) {
    if (data.isEmpty) return const SizedBox();
    final startTime = data.first.time;
    final spots = data
        .map((p) =>
            FlSpot(p.time.difference(startTime).inMinutes.toDouble(), p.value))
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
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(value.toStringAsFixed(0),
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
            getTitlesWidget: (value, meta) {
              final t = startTime.add(Duration(minutes: value.round()));
              final label =
                  (_selectedPeriod == '7d' || _selectedPeriod == '30d')
                      ? '${t.day}/${t.month}'
                      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child:
                    Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
          curveSmoothness: 0.3,
          color: color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
            final t = startTime.add(Duration(minutes: spot.x.round()));
            return LineTooltipItem(
              '${spot.y.toStringAsFixed(1)} $unit\n',
              TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              children: [
                TextSpan(
                  text:
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ));
  }
}
