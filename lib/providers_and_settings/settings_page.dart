import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

// Settings Page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Color Blind Mode
          ListTile(
            title: const Text('Color Blind Mode'),
            subtitle: const Text('Adds shapes to color-coded elements'),
            trailing: AdaptiveSwitch(
              value: settings.colorBlindMode,
              onChanged: (_) => settings.toggleColorBlindMode(),
            ),
          ),
          const Divider(),

          // Units (kg/lbs)
          ListTile(
            title: const Text('Measurement Units'),
            subtitle: Text(settings.useMetric ? 'Kilograms (kg)' : 'Pounds (lbs)'),
            trailing: AdaptiveSwitch(
              value: settings.useMetric,
              onChanged: (_) => settings.toggleUnits(),
            ),
          ),
          const Divider(),

          // Dark Theme
          ListTile(
            title: const Text('Dark Theme'),
            trailing: AdaptiveSwitch(
              value: settings.themeMode == 'dark',
              onChanged: (_) => settings.toggleTheme(),
            ),
          ),
          const Divider(),

          // Sounds
          ListTile(
            title: const Text('Enable Sounds'),
            trailing: AdaptiveSwitch(
              value: settings.soundsEnabled,
              onChanged: (_) => settings.toggleSounds(),
            ),
          ),
          const Divider(),

          // Haptics
          ListTile(
            title: const Text('Enable Haptic Feedback'),
            trailing: AdaptiveSwitch(
              value: settings.hapticsEnabled,
              onChanged: (_) => settings.toggleHaptics(),
            ),
          ),
        ],
      ),
    );
  }
}
