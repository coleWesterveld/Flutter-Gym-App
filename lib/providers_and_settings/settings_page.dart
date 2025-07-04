import 'package:firstapp/notifications/notification_service.dart';
import 'package:firstapp/providers_and_settings/ui_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'package:firstapp/providers_and_settings/program_provider.dart';

// Some things I kinda want to add
// Font Size (normal or big)
// Export program?
// Adjustable colours?
// Possible integrations with watches or myFitnessPal or something
// Volume button control for workout navigation
// Large touch targets mode
// Screen reader optimizations

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

             ListTile(
              title: const Text('Theme'),
              trailing: DropdownButton<String>(
                value: settings.themeMode,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    settings.changeTheme(newValue);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'dark',
                    child: Text("Dark"),
                  ),
                  DropdownMenuItem(
                    value: 'system',
                    child: Text("System"),
                  ),
                  DropdownMenuItem(
                    value: 'light',
                    child: Text("Light"),
                  )
                ]
              ),
            ),

            const Divider(
              thickness: 0.5,
            ),
            // Units (kg/lbs)
            ListTile(
              title: const Text('Measurement Units'),
              trailing: DropdownButton<bool>(
                value: settings.useMetric,
                onChanged: (bool? newValue) {
                  if (newValue != null && newValue != settings.useMetric) {
                    settings.toggleUnits();
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: false,
                    child: Text("Pounds/Imperial (lb)"),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text("Kilograms/Metric (kg)"),
                  )
                ]
              ),
            ),

            const Divider(
              thickness: 0.5,
            ),        
            // Dark Theme
           
        
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
            const Divider(
              thickness: 0.5,
            ),

            ListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text("Get notified of upcoming workout and to bring equipment such as a belt or straps"),
              trailing: Switch.adaptive(
                value: settings.notificationsEnabled,
                onChanged: (isEnabled) {
                  settings.toggleNotifications(context);

                  final notiService = NotiService();
                  if (isEnabled){
                    notiService.scheduleWorkoutNotifications(
                      profile: context.read<Profile>(),
                      settings: context.read<SettingsModel>(),
                    );
                  } else{
                    notiService.cancelAllNotifications();
                  }
                  
                },
              ),
            ),

            if (settings.notificationsEnabled) 
              ListTile(
                minLeadingWidth: 12,
                leading: const SizedBox.shrink(),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Notify "),
                    const SizedBox(width: 12),

                    DropdownButton<int>(
                      value: settings.timeReminder,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          settings.setTimeReminder(newValue, context);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 15,
                          child: Text("15 Mins"),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text("30 Mins"),
                        ),
                        DropdownMenuItem(
                          value: 45,
                          child: Text("45 Mins"),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text("1 Hr"),
                        ),
                        DropdownMenuItem(
                          value: 75,
                          child: Text("1 Hr 15 Mins"),
                        ),
                        DropdownMenuItem(
                          value: 90,
                          child: Text("1 Hr 30 Mins"),
                        ),
                        DropdownMenuItem(
                          value: 105,
                          child: Text("1 Hr 45 Mins"),
                        ),
                        DropdownMenuItem(
                          value: 120,
                          child: Text("2 Hr"),
                        ),
                        DropdownMenuItem(
                          value: 180,
                          child: Text("3 Hr"),
                        ),

                      ]
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Before a Workout",
                    )
                  ]
                ),
              ),
              const Divider(
              thickness: 0.5,
            ),
              // Color Blind Mode -- Yet to Be implemented
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
              // Color Blind Mode -- Yet to Be implemented
            ElevatedButton(
              onPressed: (){
                showDialog(
                  context: context, 
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Do an App Walkthrough?", textAlign: TextAlign.center,),
                      content: const Text(
                        "This is the same walkthrough you did when you first downloaded the app.",
                        textAlign: TextAlign.center,
                      ),
                      actions: [
                        TextButton(
                            onPressed: () =>Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),

                          TextButton(
                            onPressed: () async {
                              settings.startTutorial(dbWrite: false);
                              // 1. Set the flag in UiStateProvider
                              context.read<UiStateProvider>().requestTutorialReplay();

                              // 2. Pop the dialog
                              Navigator.pop(context); // Close the AlertDialog

                              // 3. Pop the SettingsPage to return to the previous screen (MainScaffold)
                              Navigator.pop(context); // Close the SettingsPage
                            },
                            child: const Text('Continue'),
                          ),
                      ],
                    );
                  },
                );
              }, 
              child: const Text("App Walkthrough")
            )
            
          ],
        ),
      ),
    );
  }
}
