import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/device.dart';

/// Device Service - Quản lý thiết bị
class DeviceService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final String? token;
  
  DeviceService({this.token});
  
  // Lấy headers với token
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  
  // Lấy danh sách tất cả thiết bị
  Future<List<Device>> getDevices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Device.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting devices: $e');
      return [];
    }
  }
  
  // Lấy thông tin một thiết bị
  Future<Device?> getDevice(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices/$deviceId'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Device.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting device: $e');
      return null;
    }
  }
  
  // Bật/tắt thiết bị
  Future<bool> toggleDevice(String deviceId, bool isOn) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devices/$deviceId/toggle'),
        headers: _headers,
        body: jsonEncode({'isOn': isOn}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling device: $e');
      return false;
    }
  }
  
  // Cập nhật thuộc tính thiết bị
  Future<bool> updateDeviceProperty(
    String deviceId,
    String property,
    dynamic value,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/devices/$deviceId/property'),
        headers: _headers,
        body: jsonEncode({
          'property': property,
          'value': value,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating device property: $e');
      return false;
    }
  }
  
  // Thêm thiết bị mới
  Future<Device?> addDevice(Device device) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devices'),
        headers: _headers,
        body: jsonEncode(device.toJson()),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Device.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error adding device: $e');
      return null;
    }
  }
  
  // Xóa thiết bị
  Future<bool> deleteDevice(String deviceId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/devices/$deviceId'),
        headers: _headers,
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting device: $e');
      return false;
    }
  }
  
  // Lấy danh sách thiết bị theo phòng
  Future<List<Device>> getDevicesByRoom(String room) async {
    try {
      final devices = await getDevices();
      return devices.where((d) => d.room == room).toList();
    } catch (e) {
      print('Error getting devices by room: $e');
      return [];
    }
  }
}
