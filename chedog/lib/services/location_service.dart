import 'dart:io';
import 'package:geolocator/geolocator.dart';
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
        return _defaultLocation('Dich vu vi tri dang tat tren thiet bi/emulator');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _requestLocationPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _defaultLocation('Chua cap quyen vi tri cho ung dung');
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return DeviceLocation(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          label:
              'Vi tri gan nhat (${lastKnown.latitude.toStringAsFixed(4)}, ${lastKnown.longitude.toStringAsFixed(4)})',
          fromDevice: true,
        );
      }

      final settings = _locationSettings();

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: settings,
        ).timeout(const Duration(seconds: 15));
      } catch (_) {
        position = await Geolocator.getPositionStream(
          locationSettings: settings,
        ).first.timeout(const Duration(seconds: 15));
      }

      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        label:
            'Vi tri hien tai (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
        fromDevice: true,
      );
    } catch (e) {
      return _defaultLocation('Khong lay duoc GPS: $e');
    }
  }

  Future<LocationPermission> _requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Returns true if current permission is only "while in use" (not always/background).
  /// On Android 10+, "Allow all the time" cannot be shown in a dialog —
  /// the user must be sent to App Settings manually.
  Future<bool> needsBackgroundPermissionViaSettings() async {
    final permission = await Geolocator.checkPermission();
    return Platform.isAndroid &&
        permission == LocationPermission.whileInUse;
  }

  /// Opens the app's system settings page so the user can change
  /// location permission from "While using" to "Allow all the time".
  Future<void> openAppSettingsForBackground() async {
    await Geolocator.openAppSettings();
  }

  LocationSettings _locationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        forceLocationManager: false,
        intervalDuration: Duration(seconds: 2),
      );
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.medium,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
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
}
