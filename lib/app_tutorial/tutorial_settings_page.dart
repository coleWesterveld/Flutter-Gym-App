import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import '../providers_and_settings/settings_provider.dart';
import '../main.dart'; // To navigate to MainScaffold
import 'app_tutorial_keys.dart';
import 'tutorial_manager.dart'; // Import the manager
import 'package:firstapp/workout_page/workout_selection_page.dart';

class TutorialSettingsPage extends StatelessWidget {
  const TutorialSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access SettingsModel if you want to show initial settings here
    // final settings = Provider.of<SettingsModel>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("Set up your initial preferences (optional):"),
          const SizedBox(height: 20),
          // --- Add Initial Settings Widgets Here (e.g., Units) ---
          // Example:
          // ListTile(
          //   title: const Text('Measurement Units'),
          //   trailing: DropdownButton<bool>(...)
          // ),
          // const Divider(),
          // --- End Initial Settings Widgets ---

          const Spacer(), // Pushes button to the bottom

                ElevatedButton(
            key: AppTutorialKeys.tutorialStartButton,
            child: const Text('Start App Tutorial'),
            onPressed: () {
              // Navigate to the main app, PASSING A FLAG to start the tutorial
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  // Pass 'startTutorial: true' as an argument
                  settings: const RouteSettings(arguments: {'startTutorial': true}),
                  builder: (context) => ShowCaseWidget( // Keep ShowCaseWidget here
                    builder: (context) => MainScaffoldWrapper(),
                    
                    onFinish: () {
                      // Mark tutorial as complete when the whole sequence finishes
                      // Use Provider safely here if needed, but check context
                      try {
                        Provider.of<SettingsModel>(context, listen: false)
                            .completeTutorial();
                        print("Tutorial Finished and Marked as Complete!");
                      } catch (e) {
                        print("Error accessing SettingsModel onFinish: $e");
                        // Handle potential context issue if SettingsModel isn't universally available
                      }
                    },

                    
                  ),
                ),
              );

              // REMOVED: Do NOT try to start the tutorial from this context
              // WidgetsBinding.instance.addPostFrameCallback((_) {
              //    Provider.of<TutorialManager>(context, listen: false) // << ERROR HAPPENS HERE
              //        .startTutorialSequence(context);
              //  });
            },
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
          ),
          const SizedBox(height: 20), // Spacing at the bottom
        ],
      ),
    );
    
  }
}

// Helper Wrapper to provide TutorialManager
class MainScaffoldWrapper extends StatelessWidget {
  final GlobalKey<MainScaffoldState> mainScaffoldKey = GlobalKey<MainScaffoldState>();
  final GlobalKey<WorkoutSelectionPageState> workoutPageKey = GlobalKey<WorkoutSelectionPageState>(); // Key for Workout Page State

  MainScaffoldWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (_) =>Builder( // Use Builder here to get a context descendant of ShowCaseWidget
        builder: (showcaseContext) { // Use this context for ShowCaseWidget.of()
           return ChangeNotifierProvider(
              create: (_) => TutorialManager(
                mainScaffoldKey: mainScaffoldKey,
                workoutPageKey: workoutPageKey,
              ),
              child: MainScaffold(
                key: mainScaffoldKey,
                workoutPageKey: workoutPageKey,
                showcaseContext: showcaseContext, // Pass the showcase context
              ),
            );
        },
      ),
       onFinish: () {
          try {
            // This onFinish will be called when the entire ShowCase sequence is done
            Provider.of<SettingsModel>(context, listen: false)
                .completeTutorial();
            print("Tutorial Finished and Marked as Complete!");
          } catch (e) {
            print("Error accessing SettingsModel onFinish: $e");
          }
        },
    );
  }
}