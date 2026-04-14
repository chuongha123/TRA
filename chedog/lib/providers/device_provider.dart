import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../services/device_service.dart';

/// Device Provider - Quản lý state của devices
class DeviceProvider with ChangeNotifier {
  final DeviceService _deviceService;
  
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;
  
  DeviceProvider(this._deviceService);
  
  // Getters
  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Lấy danh sách thiết bị online
  List<Device> get onlineDevices => 
      _devices.where((d) => d.isOnline).toList();
  
  // Lấy danh sách thiết bị offline
  List<Device> get offlineDevices => 
      _devices.where((d) => !d.isOnline).toList();
  
  // Lấy danh sách thiết bị đang bật
  List<Device> get activeDevices => 
      _devices.where((d) => d.isOn).toList();
  
  // Lấy thiết bị theo room
  List<Device> getDevicesByRoom(String room) =>
      _devices.where((d) => d.room == room).toList();
  
  // Lấy thiết bị theo type
  List<Device> getDevicesByType(String type) =>
      _devices.where((d) => d.type == type).toList();
  
  // Load danh sách thiết bị
  Future<void> loadDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _devices = await _deviceService.getDevices();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Toggle thiết bị
  Future<bool> toggleDevice(String deviceId) async {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    final newState = !device.isOn;
    
    final success = await _deviceService.toggleDevice(deviceId, newState);
    
    if (success) {
      final index = _devices.indexWhere((d) => d.id == deviceId);
      _devices[index] = device.copyWith(
        isOn: newState,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
    
    return success;
  }
  
  // Cập nhật thuộc tính thiết bị
  Future<bool> updateDeviceProperty(
    String deviceId,
    String property,
    dynamic value,
  ) async {
    final success = await _deviceService.updateDeviceProperty(
      deviceId,
      property,
      value,
    );
    
    if (success) {
      final device = _devices.firstWhere((d) => d.id == deviceId);
      final index = _devices.indexWhere((d) => d.id == deviceId);
      final properties = Map<String, dynamic>.from(device.properties ?? {});
      properties[property] = value;
      
      _devices[index] = device.copyWith(
        properties: properties,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
    
    return success;
  }
  
  // Thêm thiết bị mới
  Future<bool> addDevice(Device device) async {
    final newDevice = await _deviceService.addDevice(device);
    
    if (newDevice != null) {
      _devices.add(newDevice);
      notifyListeners();
      return true;
    }
    
    return false;
  }
  
  // Xóa thiết bị
  Future<bool> deleteDevice(String deviceId) async {
    final success = await _deviceService.deleteDevice(deviceId);
    
    if (success) {
      _devices.removeWhere((d) => d.id == deviceId);
      notifyListeners();
    }
    
    return success;
  }
  
  // Cập nhật trạng thái realtime từ WebSocket/MQTT
  void updateDeviceStatus(String deviceId, Map<String, dynamic> status) {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(
        isOnline: status['isOnline'] ?? _devices[index].isOnline,
        isOn: status['isOn'] ?? _devices[index].isOn,
        properties: status['properties'] ?? _devices[index].properties,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }
}
