import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SettingsModel extends ChangeNotifier {
  bool _colorBlindMode = false;
  bool _useMetric = true;
  bool _darkTheme = false;
  bool _soundsEnabled = true;
  bool _hapticsEnabled = true;

  bool get colorBlindMode => _colorBlindMode;
  bool get useMetric => _useMetric;
  bool get darkTheme => _darkTheme;
  bool get soundsEnabled => _soundsEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  void toggleColorBlindMode() {
    _colorBlindMode = !_colorBlindMode;
    notifyListeners();
  }

  void toggleUnits() {
    _useMetric = !_useMetric;
    notifyListeners();
  }

  void toggleTheme() {
    _darkTheme = !_darkTheme;
    notifyListeners();
  }

  void toggleSounds() {
    _soundsEnabled = !_soundsEnabled;
    notifyListeners();
  }

  void toggleHaptics() {
    _hapticsEnabled = !_hapticsEnabled;
    notifyListeners();
  }
}

// Platform-adaptive switch widget
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
