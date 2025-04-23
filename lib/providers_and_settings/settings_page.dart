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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            // Color Blind Mode
            ListTile(
              title: const Text('Color Blind Mode'),
              subtitle: const Text('Adds shapes to color-coded elements'),
              trailing: Switch.adaptive(
                value: settings.colorBlindMode,
                onChanged: (_) => settings.toggleColorBlindMode(),
              ),
            ),
            const Divider(
              thickness: 0.5,
            ),
        
            // Units (kg/lbs)
            ListTile(
              title: const Text('Measurement Units'),
              trailing: Switch.adaptive(
                value: settings.useMetric,
                onChanged: (_) => settings.toggleUnits(),
              ),
            ),

            const Divider(
              thickness: 0.5,
            ),        
            // Dark Theme
            ListTile(
              title: const Text('Dark Theme'),
              trailing: Switch.adaptive(
                value: settings.themeMode == 'dark',
                onChanged: (_) => settings.toggleTheme(),
              ),
            ),

            const Divider(
              thickness: 0.5,
            ),
        
            // // Sounds - Theres currently no sounds in the app
            // ListTile(
            //   title: const Text('Enable Sounds'),
            //   trailing: Switch.adaptive(
            //     value: settings.soundsEnabled,
            //     onChanged: (_) => settings.toggleSounds(),
            //   ),
            // ),

            // const Divider(
            //   thickness: 0.5,
            // ),
        
            // Haptics
            ListTile(
              title: const Text('Enable Haptic Feedback'),
              trailing: Switch.adaptive(
                value: settings.hapticsEnabled,
                onChanged: (_) => settings.toggleHaptics(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
