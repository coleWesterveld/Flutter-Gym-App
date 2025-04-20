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
  );

  // Getters
  UserSettings get settings => _settings;
  bool get colorBlindMode => _settings.colourBlindMode;
  bool get useMetric => _settings.useMetric;
  String get themeMode => _settings.themeMode;
  bool get soundsEnabled => _settings.enableSound;
  bool get hapticsEnabled => _settings.enableHaptics;

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

  // TODO: this should be a dropdown with dark, light and system
  Future<void> toggleTheme() async {
    final newTheme = _settings.themeMode == 'dark' ? 'light' : 'dark';
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

  // For more complex updates
  Future<void> updateSettings(UserSettings newSettings) async {
    _settings = newSettings;
    await dbHelper.updateUserSettings(_settings);
    notifyListeners();
  }
}

// Updated Platform-adaptive switch widget
class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdaptiveSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    return isIOS
        ? CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: CupertinoColors.activeBlue,
          )
        : Switch(
            value: value,
            onChanged: onChanged,
          );
  }
}
