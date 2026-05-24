import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide preferences (theme, notifications, language label).
class AppSettingsController extends ChangeNotifier {
  static const _themeModeKey = 'chargix_theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;
  bool _notificationsEnabled = true;
  String _languageCode = 'en';
  bool _preferFastCharging = true;
  bool _autoBookNearest = true;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get languageCode => _languageCode;
  bool get preferFastCharging => _preferFastCharging;
  bool get autoBookNearest => _autoBookNearest;
  bool get isLoaded => _loaded;

  String get languageLabel =>
      _languageCode == 'ar' ? 'العربية' : 'English';

  bool get isDarkMode =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_themeModeKey);
      if (stored != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (m) => m.name == stored,
          orElse: () => ThemeMode.dark,
        );
      }
    } on Object catch (_) {
      _themeMode = ThemeMode.dark;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } on Object catch (_) {}
  }

  void setDarkMode(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void setNotificationsEnabled(bool value) {
    if (_notificationsEnabled == value) {
      return;
    }
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setLanguageCode(String code) {
    if (_languageCode == code) {
      return;
    }
    _languageCode = code;
    notifyListeners();
  }

  void setPreferFastCharging(bool value) {
    if (_preferFastCharging == value) {
      return;
    }
    _preferFastCharging = value;
    notifyListeners();
  }

  void setAutoBookNearest(bool value) {
    if (_autoBookNearest == value) {
      return;
    }
    _autoBookNearest = value;
    notifyListeners();
  }
}
