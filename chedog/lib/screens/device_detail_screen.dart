import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Device Detail Screen - Chi tiết thiết bị
class DeviceDetailScreen extends StatefulWidget {
  const DeviceDetailScreen({super.key});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _isOn = true;
  double _brightness = 75;
  double _temperature = 24;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 Garden Controller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Edit device
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Delete device
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Icon & Status
            _buildDeviceHeader(),
            const SizedBox(height: 32),
            
            // Power Control
            _buildPowerSwitch(),
            const SizedBox(height: 32),
            
            // Brightness Control
            _buildBrightnessControl(),
            const SizedBox(height: 32),
            
            // Temperature Control (for AC/Heater)
            _buildTemperatureControl(),
            const SizedBox(height: 32),
            
            // Device Info
            _buildDeviceInfo(),
            const SizedBox(height: 32),
            
            // Quick Actions
            _buildQuickActionsGrid(),
            const SizedBox(height: 32),
            
            // Energy Usage Chart
            _buildEnergyUsageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: _isOn 
                  ? AppColors.primaryGradient
                  : LinearGradient(
                      colors: [Colors.grey[300]!, Colors.grey[400]!],
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isOn ? AppColors.primary : Colors.grey)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.water_drop,
              size: 60,
              color: _isOn ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ESP32 Garden Sensor',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.deviceOnline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Online'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPowerSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Power',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  _isOn ? 'Device is ON' : 'Device is OFF',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            Switch(
              value: _isOn,
              onChanged: (value) {
                setState(() {
                  _isOn = value;
                });
              },
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessControl() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Brightness',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${_brightness.toInt()}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.brightness_low,
                  color: Theme.of(context).iconTheme.color,
                ),
                Expanded(
                  child: Slider(
                    value: _brightness,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: _isOn ? (value) {
                      setState(() {
                        _brightness = value;
                      });
                    } : null,
                  ),
                ),
                Icon(
                  Icons.brightness_high,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureControl() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Temperature',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${_temperature.toInt()}°C',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.ac_unit,
                  color: Theme.of(context).iconTheme.color,
                ),
                Expanded(
                  child: Slider(
                    value: _temperature,
                    min: 16,
                    max: 30,
                    divisions: 14,
                    onChanged: _isOn ? (value) {
                      setState(() {
                        _temperature = value;
                      });
                    } : null,
                  ),
                ),
                Icon(
                  Icons.local_fire_department,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Device ID', AppConstants.esp32DefaultHost),
            const Divider(),
            _buildInfoRow('Type', AppConstants.deviceTypeController),
            const Divider(),
            _buildInfoRow('Location', 'Vườn rau A'),
            const Divider(),
            _buildInfoRow('Last Update', 'Fetching...'),
            const Divider(),
            _buildInfoRow('Firmware', 'Check device'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildActionCard(Icons.history, 'History', () {}),
            _buildActionCard(Icons.settings, 'Settings', () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyUsageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy Usage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Today: 2.4 kWh',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // TODO: Add chart here
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Chart Placeholder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
