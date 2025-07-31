import 'package:flutter/material.dart';
import 'usga_theme.dart';

/// Theme manager for handling light/dark mode switching
class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  ThemeData get currentTheme => _isDarkMode ? USGATheme.darkTheme : USGATheme.lightTheme;
}
