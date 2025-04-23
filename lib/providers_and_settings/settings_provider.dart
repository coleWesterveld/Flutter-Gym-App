import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../database/database_helper.dart';
import '../database/profile.dart';

class SettingsModel extends ChangeNotifier {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  UserSettings _settings = UserSettings(
    enableHaptics: true,
    enableSound: true,
    themeMode: 'system',
    useMetric: false,
    colourBlindMode: false,
    enableNotifications: true,
    timeReminder: 30,
  );

  // Getters
  UserSettings get settings => _settings;
  bool get colorBlindMode => _settings.colourBlindMode;
  bool get useMetric => _settings.useMetric;
  String get themeMode => _settings.themeMode;
  bool get soundsEnabled => _settings.enableSound;
  bool get hapticsEnabled => _settings.enableHaptics;
  bool get notificationsEnabled => _settings.enableNotifications;
  int get timeReminder => _settings.timeReminder;



  // Initialize settings
  Future<void> init() async {
    final potentialSettings = await dbHelper.fetchUserSettings();
    if (potentialSettings != null) {
      _settings = potentialSettings;
      notifyListeners();
    }

  }

  // Toggle methods
  Future<void> toggleColorBlindMode() async {
    _settings = _settings.copyWith(
      colourBlindMode: !_settings.colourBlindMode,
    );
    await dbHelper.updateUserSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleUnits() async {
    _settings = _settings.copyWith(
      useMetric: !_settings.useMetric,
    );
    await dbHelper.updateUserSettings(_settings);
    notifyListeners();
  }

  Future<void> changeTheme(String newTheme) async {
    assert(['dark', 'light', 'system'].contains(newTheme), "Theme $newTheme not one of: light, dark, or system");

    _settings = _settings.copyWith(themeMode: newTheme);

    await dbHelper.updateUserSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleSystemTheme() async {
    _settings = _settings.copyWith(themeMode: 'system');
    await dbHelper.updateUserSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleSounds() async {
    _settings = _settings.copyWith(
      enableSound: !_settings.enableSound,
    );
    await dbHelper.updateUserSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleHaptics() async {
    _settings = _settings.copyWith(
      enableHaptics: !_settings.enableHaptics,
    );
    await dbHelper.updateUserSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _settings = _settings.copyWith(
      enableNotifications: !_settings.enableNotifications,
    );
    await dbHelper.updateUserSettings(_settings);
    notifyListeners();
  }

  Future<void> setTimeReminder(int newValue) async {
    _settings = _settings.copyWith(
      timeReminder: newValue,
    );
    await dbHelper.updateUserSettings(_settings);
    notifyListeners();
  }

  // For more complex updates
  Future<void> updateSettings(UserSettings newSettings) async {
    _settings = newSettings;
    await dbHelper.updateUserSettings(_settings);
    notifyListeners();
  }
}
