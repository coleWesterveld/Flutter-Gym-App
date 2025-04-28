import 'package:firstapp/program_page/program_page.dart';
import 'package:firstapp/providers_and_settings/ui_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'app_tutorial_keys.dart';
import '../main.dart'; // Access MainScaffoldState
import '../workout_page/workout_selection_page.dart'; // Access WorkoutSelectionPageState
import 'package:provider/provider.dart';
import 'package:firstapp/providers_and_settings/settings_provider.dart';



class TutorialManager extends ChangeNotifier {
  final GlobalKey<MainScaffoldState> mainScaffoldKey;
  final GlobalKey<WorkoutSelectionPageState> workoutPageKey; // Key to access workout page state
  final GlobalKey<ProgramPageState> programPageKey; // Key to access workout page state


  TutorialManager({
    required this.mainScaffoldKey, 
    required this.workoutPageKey,
    required this.programPageKey,
  });

  // Define the sequence of keys
  final List<GlobalKey> _tutorialSequence = [
    AppTutorialKeys.settingsButton,
    AppTutorialKeys.editPrograms,
    AppTutorialKeys.addDayToProgram,
    AppTutorialKeys.addExerciseToProgram,
    AppTutorialKeys.editScheduleButton,
    AppTutorialKeys.startWorkout,
    AppTutorialKeys.recentWorkouts,
    AppTutorialKeys.addGoals
    // Add other keys in the desired order
  ];

  final exerciseDemoExpandController = ExpansionTileController();
  final workoutDemoController = ExpansionTileController();

  int _currentStep = 0;

  late BuildContext _ctx;    // we’ll capture this so our buttons can call back in
  void startTutorialSequence(BuildContext showCaseContext) {
    _ctx = showCaseContext;
    _currentStep = 0;
    _executeStep(showCaseContext);
  }



  void advanceStep() {
    _currentStep++;
    _executeStep(_ctx);
  }

  void skipTutorial() {
    // 1) Mark in SettingsModel that tutorial is complete
    Provider.of<SettingsModel>(_ctx, listen: false).completeTutorial();

    // 2) Dismiss the currently visible tooltip
    final scState = ShowCaseWidget.of(_ctx);
    
    scState.dismiss();     // hides the current showcase bubble immediately
    showCompletionPrompt();

    // 3) Prevent any future steps from running
    _currentStep = _tutorialSequence.length;
  }


  // Gets called for every showcase - defines flow for a single widget to showcase
  Future<void> _executeStep(BuildContext showCaseContext) async {
    // If we have shown all the widgets, we are done
    if (_currentStep >= _tutorialSequence.length) {
        showCompletionPrompt();

      // Sequence finished, ShowCaseWidget's onFinish will handle completion
      print("Tutorial sequence complete.");
      final scState = ShowCaseWidget.of(_ctx);
      
      scState.dismiss();     // hides the current showcase bubble immediately
      
      return;
    }

    // set active widget's key
    final currentKey = _tutorialSequence[_currentStep];

    //Pre-Showcase required navigation or expansion or opening drawers to display a widget, etc.
    await _prepareForStep(showCaseContext, currentKey);

    // Now actually calls showcase on the current widget
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
                 // For simplicity here, we'll advance after ax delay, assuming the user reads it.
                 // A better approach involves custom tooltips with a "Next" button.

                //  Future.delayed(const Duration(seconds: 3), () { // Adjust delay as needed
                                     // _currentStep++;

                //      _executeStep(showCaseContext); // Move to the next step
                //  });
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
    final uiState = context.read<UiStateProvider>();
    // --- Navigation Logic ---
    int targetPageIndex = -1;
    if (key == AppTutorialKeys.settingsButton || key == AppTutorialKeys.editPrograms /*|| key == AppTutorialKeys.programDayTile*/) {
      targetPageIndex = 2; // Program Page index
    // } else if (key == AppTutorialKeys.workoutDayTile || key == AppTutorialKeys.startWorkoutButton) {
    //   targetPageIndex = 0; // Workout Page index
    }
    // Add more pages as needed

    if (targetPageIndex != -1 && uiState.currentPageIndex != targetPageIndex) {
      uiState.currentPageIndex = targetPageIndex;
      // Wait for navigation animation (adjust duration if needed)
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // if (key == AppTutorialKeys.editPrograms) {
    //   //await Future.delayed(const Duration(milliseconds: 800)); // Adjust delay as needed

    //   //debugPrint("we are on step to show add program button");
    //     // Ensure the Program Page is active before trying to open the drawer
    //     if (uiState.currentPageIndex == 2) { // 2 is Program Page index
    //          try {
    //                 //debugPrint("boom");

    //             // *** CALL THE METHOD ON MainScaffoldState ***
    //             mainScaffoldKey.currentState?.openProgramDrawer();

    //             //print("Attempting to open drawer for Add Program tutorial step.");
    //             // Wait for the drawer animation to complete and content to render
    //             //await Future.delayed(const Duration(milliseconds: 300)); // Adjust delay as needed
    //             //print("Drawer likely open.");

    //          } catch (e) {
    //             print("Error calling openProgramDrawer: $e");
    //             // This catch might be less likely now, as Scaffold.of is in MainScaffoldState
    //          }
    //     }
    // }

    // --- Expansion Logic ---
    if (key == AppTutorialKeys.addExerciseToProgram) {
      // Find the index of the tile to expand (e.g., today's workout)
      // This logic depends on how you identify "today's workout" in WorkoutSelectionPage
      //int tileIndexToExpand = programPageKey.currentState?.toExpand() ?? -1; // Use your existing logic

     // if (tileIndexToExpand != -1) {
        //print("Attempting to expand tile at index: $tileIndexToExpand");
        // Call the expand method on the WorkoutSelectionPage state

        // TODO: maybe protect this? no guarantee its attached though it should be
        exerciseDemoExpandController.expand();

        // Wait for expansion animation
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint("Start next ");
         //print("Expansion likely complete for index: $tileIndexToExpand");
      // } else {
      //    print("Warning: Could not determine which workout tile to expand for tutorial.");
      // }
    }
    if (key == AppTutorialKeys.editScheduleButton){
       uiState.currentPageIndex = 1;
      // Wait for navigation animation (adjust duration if needed)
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (key == AppTutorialKeys.startWorkout){
      uiState.currentPageIndex = 0;
      workoutPageKey.currentState?.expandTile(0);
      // Wait for navigation animation (adjust duration if needed)
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (key == AppTutorialKeys.recentWorkouts || key == AppTutorialKeys.addGoals){
      uiState.currentPageIndex = 3;
      // Wait for navigation animation (adjust duration if needed)
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Add more preparation logic (scrolling, etc.) if needed
  }

  void showCompletionPrompt() {
    final uiState = _ctx.read<UiStateProvider>();
  showModalBottomSheet(
    context: _ctx,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You're all set!",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Would you like to create your very first program now, or explore the app on your own?",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
            onPressed: ()async {
            uiState.currentPageIndex = 2;
            Navigator.pop(context);
            await Future.delayed(Duration(milliseconds: 500));

            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint("📢 postFrameCallback fired");
              final msState = mainScaffoldKey.currentState;
              debugPrint("🔑 mainScaffoldKey.currentState = $msState");
              msState?.openProgramDrawer();
            });
          },

            child: const Text("Create First Program"),
          ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);           // close sheet
                // nothing else, let them explore
              },
              child: const Text("Explore on Your Own"),
            ),
          ],
        ),
      );
    },
  );
}

}