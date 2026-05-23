import 'package:flutter/material.dart';

/// App-wide preferences (theme, notifications, language label).
///
/// Persists in memory for this session; wire to [SharedPreferences] later if needed.
class AppSettingsController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  String _languageCode = 'en';
  bool _preferFastCharging = true;
  bool _autoBookNearest = true;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get languageCode => _languageCode;
  bool get preferFastCharging => _preferFastCharging;
  bool get autoBookNearest => _autoBookNearest;

  String get languageLabel =>
      _languageCode == 'ar' ? 'العربية' : 'English';

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
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
