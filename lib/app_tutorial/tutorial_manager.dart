import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'app_tutorial_keys.dart';
import '../main.dart'; // Access MainScaffoldState
import '../workout_page/workout_selection_page.dart'; // Access WorkoutSelectionPageState

class TutorialManager extends ChangeNotifier {
  final GlobalKey<MainScaffoldState> mainScaffoldKey;
  final GlobalKey<WorkoutSelectionPageState> workoutPageKey; // Key to access workout page state

  TutorialManager({required this.mainScaffoldKey, required this.workoutPageKey});

  // Define the sequence of keys
  final List<GlobalKey> _tutorialSequence = [
    AppTutorialKeys.settingsButton,
    AppTutorialKeys.addProgram,
    // AppTutorialKeys.programDayTile, // Example step
    // AppTutorialKeys.workoutDayTile,
    // AppTutorialKeys.startWorkoutButton,
    // Add other keys in the desired order
  ];

  int _currentStep = 0;

  // Method to start the entire sequence
  void startTutorialSequence(BuildContext showCaseContext) {
    // Ensure we start fresh if called again
    _currentStep = 0;
    _executeStep(showCaseContext);
  }

  // Recursive or iterative method to execute steps
  Future<void> _executeStep(BuildContext showCaseContext) async {
    if (_currentStep >= _tutorialSequence.length) {
      // Sequence finished, ShowCaseWidget's onFinish will handle completion
      print("Tutorial sequence complete.");
      // Optionally call completeTutorial here if onFinish isn't reliable
      // Provider.of<SettingsModel>(context, listen: false).completeTutorial();
      return;
    }

    final currentKey = _tutorialSequence[_currentStep];

    // --- Pre-Showcase Actions (Navigation, Expansion) ---
    await _prepareForStep(showCaseContext, currentKey);

    // --- Start Showcase for the current key ---
    // Use addPostFrameCallback to ensure the UI is ready after preparations
    WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
             // Find the ShowCaseWidget context
            ShowCaseWidgetState? showCaseState = ShowCaseWidget.of(showCaseContext);
            if (showCaseState != null) {
                 showCaseState.startShowCase([currentKey]);
                 // Setup listener for when this step is dismissed
                 // Unfortunately, showcaseview doesn't have a direct per-step callback.
                 // We might need to rely on timing or user interaction to advance.
                 // A common workaround is to advance in the 'onToolTipClick' or add delays.
                 // For simplicity here, we'll advance after a delay, assuming the user reads it.
                 // A better approach involves custom tooltips with a "Next" button.

                 Future.delayed(const Duration(seconds: 3), () { // Adjust delay as needed
                     _currentStep++;
                     _executeStep(showCaseContext); // Move to the next step
                 });
            } else {
                 print("Error: ShowCaseWidget context not found!");
                 // Handle error - maybe skip step or stop tutorial
            }

        } catch (e) {
            print("Error starting showcase for key: $e");
            // Handle error - maybe skip step or stop tutorial
             _currentStep++;
             _executeStep(showCaseContext); // Try next step even if current one failed
        }
    });
  }

  // Prepare the UI for the specific step
  Future<void> _prepareForStep(BuildContext context, GlobalKey key) async {
    // --- Navigation Logic ---
    int targetPageIndex = -1;
    if (key == AppTutorialKeys.settingsButton || key == AppTutorialKeys.addProgram /*|| key == AppTutorialKeys.programDayTile*/) {
      targetPageIndex = 2; // Program Page index
    // } else if (key == AppTutorialKeys.workoutDayTile || key == AppTutorialKeys.startWorkoutButton) {
    //   targetPageIndex = 0; // Workout Page index
    }
    // Add more pages as needed

    if (targetPageIndex != -1 && mainScaffoldKey.currentState?.currentPageIndex != targetPageIndex) {
      mainScaffoldKey.currentState?.changePage(targetPageIndex);
      // Wait for navigation animation (adjust duration if needed)
      await Future.delayed(const Duration(milliseconds: 400));
    }

    // --- Expansion Logic ---
    // if (key == AppTutorialKeys.startWorkoutButton) {
    //   // Find the index of the tile to expand (e.g., today's workout)
    //   // This logic depends on how you identify "today's workout" in WorkoutSelectionPage
    //   int tileIndexToExpand = workoutPageKey.currentState?.toExpand() ?? -1; // Use your existing logic

    //   if (tileIndexToExpand != -1) {
    //      print("Attempting to expand tile at index: $tileIndexToExpand");
    //     // Call the expand method on the WorkoutSelectionPage state
    //     workoutPageKey.currentState?.expandTile(tileIndexToExpand);
    //     // Wait for expansion animation
    //     await Future.delayed(const Duration(milliseconds: 500));
    //      print("Expansion likely complete for index: $tileIndexToExpand");
    //   } else {
    //      print("Warning: Could not determine which workout tile to expand for tutorial.");
    //   }
    // }

    // Add more preparation logic (scrolling, etc.) if needed
  }
}