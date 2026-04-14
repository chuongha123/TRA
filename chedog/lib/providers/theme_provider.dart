import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Theme Provider - Quản lý Dark/Light mode
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  
  ThemeProvider() {
    _loadThemeMode();
  }
  
  // Getter
  bool get isDarkMode => _isDarkMode;
  
  // Load theme mode từ storage
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(AppConstants.keyThemeMode) ?? false;
    notifyListeners();
  }
  
  // Toggle theme mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyThemeMode, _isDarkMode);
    
    notifyListeners();
  }
  
  // Set theme mode
  Future<void> setThemeMode(bool isDark) async {
    _isDarkMode = isDark;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyThemeMode, _isDarkMode);
    
    notifyListeners();
  }
}
