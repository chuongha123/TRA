import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class DeviceLocation {
  final double latitude;
  final double longitude;
  final String label;
  final bool fromDevice;
  final String? fallbackReason;

  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.fromDevice,
    this.fallbackReason,
  });
}

class LocationService {
  Future<DeviceLocation> getBestEffortLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _defaultLocation('Dịch vụ vị trí đang tắt trên thiết bị/emulator');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _requestLocationPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _defaultLocation('Chưa cấp quyền vị trí cho ứng dụng');
      }

      final settings = _locationSettings();

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: settings,
        ).timeout(const Duration(seconds: 15));
      } catch (_) {
        try {
          position = await Geolocator.getPositionStream(
            locationSettings: settings,
          ).first.timeout(const Duration(seconds: 15));
        } catch (_) {
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position == null) {
        return _defaultLocation('Không lấy được vị trí GPS từ thiết bị');
      }

      final addressLabel = await _resolveAddressLabel(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        label: addressLabel ??
            'Vị trí hiện tại (${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)})',
        fromDevice: true,
      );
    } catch (e) {
      return _defaultLocation('Không lấy được GPS: $e');
    }
  }

  Future<LocationPermission> _requestLocationPermission() async {
    // Request foreground first.
    LocationPermission permission = await Geolocator.requestPermission();

    // Try one more escalation pass for platforms supporting background/always.
    // Android 11+ may still require users to enable "Allow all the time" in app settings.
    if ((Platform.isAndroid || Platform.isIOS) &&
        permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  LocationSettings _locationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        forceLocationManager: false,
        intervalDuration: Duration(seconds: 2),
      );
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
    );
  }

  DeviceLocation _defaultLocation([String? reason]) {
    return DeviceLocation(
      latitude: AppConstants.weatherLatitude,
      longitude: AppConstants.weatherLongitude,
      label: AppConstants.weatherLocationName,
      fromDevice: false,
      fallbackReason: reason,
    );
  }

  Future<String?> _resolveAddressLabel({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse('https://geocoding-api.open-meteo.com/v1/reverse')
          .replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'language': 'vi',
          'count': '1',
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final results = data['results'];
      if (results is! List || results.isEmpty) {
        return null;
      }

      final first = results.first;
      if (first is! Map) {
        return null;
      }

      final map = Map<String, dynamic>.from(first);
      final name = (map['name'] ?? '').toString().trim();
      final admin2 = (map['admin2'] ?? '').toString().trim();
      final admin1 = (map['admin1'] ?? '').toString().trim();

      final parts = <String>[];
      if (name.isNotEmpty) parts.add(name);
      if (admin2.isNotEmpty && admin2 != name) parts.add(admin2);
      if (admin1.isNotEmpty && admin1 != admin2) parts.add(admin1);

      if (parts.isEmpty) {
        return null;
      }

      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
