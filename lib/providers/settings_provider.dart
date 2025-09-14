import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  dark,
  blueBlack,
  blueAccent,
  midnight,
  slate,
  deepPurple,
  emerald,
  sunset,
  ocean,
  ruby,
  glass,
  pureDark
}

enum AQISource { waqi, openWeatherMap, airVisual }

class SettingsProvider extends ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _dailySummaryEnabled = false;
  AppThemeMode _themeMode = AppThemeMode.blueBlack;
  AQISource _aqiSource = AQISource.waqi;
  int _refreshInterval = 30; // in minutes

  bool get notificationsEnabled => _notificationsEnabled;
  bool get dailySummaryEnabled => _dailySummaryEnabled;
  AppThemeMode get themeMode => _themeMode;
  AQISource get aqiSource => _aqiSource;
  int get refreshInterval => _refreshInterval;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _dailySummaryEnabled = prefs.getBool('dailySummaryEnabled') ?? false;
    int themeIndex = prefs.getInt('themeMode') ?? 1;
    if (themeIndex < 0 || themeIndex >= AppThemeMode.values.length)
      themeIndex = 1;
    _themeMode = AppThemeMode.values[themeIndex]; // default blueBlack
    _aqiSource = AQISource.values[prefs.getInt('aqiSource') ?? 0];
    _refreshInterval = prefs.getInt('refreshInterval') ?? 30;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  Future<void> setDailySummaryEnabled(bool value) async {
    _dailySummaryEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailySummaryEnabled', value);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setAQISource(AQISource source) async {
    _aqiSource = source;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('aqiSource', source.index);
    notifyListeners();
  }

  Future<void> setRefreshInterval(int minutes) async {
    _refreshInterval = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refreshInterval', minutes);
    notifyListeners();
  }
}
