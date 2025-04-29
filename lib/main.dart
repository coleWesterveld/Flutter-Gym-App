import 'package:firstapp/app_tutorial/app_tutorial_keys.dart';
import 'package:firstapp/providers_and_settings/active_workout_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Pages
import 'package:firstapp/workout_page/workout_selection_page.dart';       // Workout Selector
import 'package:firstapp/schedule_page/schedule_page.dart';               // Schedule Page
import 'package:firstapp/program_page/program_page.dart';                 // Program Creator
import 'package:firstapp/analytics_page/analytics_page.dart';             // Analytics Page

// Utilities
import 'package:firstapp/database/database_helper.dart';                  // Database Methods
import 'package:firstapp/widgets/workout_stopwatch.dart';                 // Active Workout Clock
import 'package:firstapp/providers_and_settings/program_provider.dart';   // Program Management
import 'package:firstapp/providers_and_settings/settings_provider.dart';  // Settings
import 'package:firstapp/theme/app_theme.dart';                           // Theme
import 'package:firstapp/notifications/notification_service.dart';        // Notifications
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:showcaseview/showcaseview.dart';        // Splash Screen

import 'package:firstapp/app_tutorial/tutorial_manager.dart'; // Import manager
import 'package:firstapp/app_tutorial/tutorial_welcome_page.dart'; // Import welcome page
import 'package:firstapp/workout_page/workout_selection_page.dart'; // Import workout page state for key
import 'package:showcaseview/showcaseview.dart'; // Import showcase
import 'package:firstapp/app_tutorial/tutorial_settings_page.dart';
import 'package:firstapp/widgets/programs_drawer.dart';
import 'package:firstapp/providers_and_settings/settings_page.dart';
import 'package:firstapp/providers_and_settings/ui_state_provider.dart';
import 'widgets/calendar_bottom_sheet.dart';

import 'package:firstapp/widgets/done_button.dart';

// TODO: add disposes for all focusnodes and TECs and other
/* colour choices:
my goal is to make tappable things blue
editable things orange 
simplify the design, get rid of unnessecary colours so that attention is drawn to whats important
*/


// thing to be aware: exercise class has id and Exercise id, do not confuse them! (this causes most of my bugs)
// this should maybe be fixed and is a bit unclear since a db restructure
// since exercise class itself references an exercise instance, which has an ID to which specific exercise it is an instance of
// id identifies the instance uniquely, exerciseID references the exercise in the big table of all the exercises.
// try with different phone sizes - its mostly reactive I think but I havent done enough testing

// ENTRYPOINT OF APP HERE
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);


  runApp(const GymApp());

}

class GymApp extends StatefulWidget {
  const GymApp({super.key});
  @override
  State<GymApp> createState() => _MainPage();
}

class _MainPage extends State<GymApp> {

  @override
  void initState() {
    super.initState();
    //Future.delayed(const Duration(seconds: 1), () {
      FlutterNativeSplash.remove();
    //});
  }


  final dbHelper = DatabaseHelper.instance;


  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final settings = SettingsModel();
            settings.init(); 
            return settings;
          }
        ),


        ChangeNotifierProvider(
          create: (context) => Profile(
            dbHelper: dbHelper,
          ),
        ),

        ChangeNotifierProxyProvider<Profile, ActiveWorkoutProvider>(


          create: (context) => ActiveWorkoutProvider(
            dbHelper: dbHelper,
            programProvider: Provider.of<Profile>(context, listen: false),
            workoutNotesTEC: [],
            workoutRepsTEC: [],
            workoutRpeTEC: [],
            workoutWeightTEC: [],
            workoutExpansionControllers: []
          ),

          update: (context, programProvider, previousActiveWorkoutProvider) {
            // In this simple case, we might not need to do much in update,
            // as ActiveWorkoutProvider reads programProvider directly when needed.
            // If ActiveWorkoutProvider held copies of program data that needed
            // syncing, you'd do it here.
             // Ensure dbHelper is passed along if needed (though create handles it)
            return previousActiveWorkoutProvider ?? ActiveWorkoutProvider(
                dbHelper: dbHelper, programProvider: programProvider);
          },
        ),

        ChangeNotifierProvider(create: (_) => UiStateProvider()),


        // ChangeNotifierProvider(
        //   create: (_) => TutorialManager(
        //     mainScaffoldKey: 
        //   )
        // ), // If wrapping higher up
      ],
      child: Consumer<SettingsModel>(
        builder: (context, settings, child) {
          if (!context.watch<Profile>().isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!settings.isFirstTime && context.watch<Profile>().isInitialized) {
            final notiService = NotiService();
            notiService.scheduleWorkoutNotifications(
              profile: context.read<Profile>(),
              settings: context.read<SettingsModel>(),
            );
          }

          Widget initialHome;
          if (settings.isFirstTime) {
            initialHome = const TutorialWelcomePage();
          } else {
            // If not first time, wrap MainScaffold in ShowCaseWidget
            // only if you want to allow replaying the tutorial later.
            // Otherwise, just show MainScaffoldWrapper directly.
             initialHome = MainScaffoldWrapper(); // Use the wrapper directly
            // initialHome = ShowCaseWidget(
            //    builder: Builder(builder: (context) => MainScaffoldWrapper()),
            // );
          }

          return MaterialApp(
            //showSemanticsDebugger: true,
            title: 'TempTitle',
            debugShowCheckedModeBanner: false,
            themeMode: _getThemeMode(settings.themeMode),
            darkTheme: AppTheme.darkTheme,
            theme: AppTheme.lightTheme,
            home: initialHome
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(String themeMode) {
    switch (themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

class MainScaffold extends StatefulWidget {
  //Function updater;
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final GlobalKey<WorkoutSelectionPageState>? workoutPageKey; // Accept the key
  final GlobalKey<ProgramPageState>? programPageKey; // Accept the key

  final BuildContext showcaseContext; // Receive the showcase context


  MainScaffold({
    super.key, 
    this.workoutPageKey, 
    required this.showcaseContext,
    required this.programPageKey,

  });

  @override
  MainScaffoldState createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  void didChangeDependencies() {
    
    super.didChangeDependencies();

    _checkAndOpenDrawer();

    // the following logic allows user to redo walkthrough from settings
    final uiState = context.watch<UiStateProvider>(); // Use watch or read as appropriate
    if (uiState.replayTutorialRequested) {
      // Use addPostFrameCallback to ensure the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Ensure the widget is still in the tree
          try {
            // Get the TutorialManager
            final manager = context.read<TutorialManager>();
            // Start the tutorial sequence using the showcaseContext passed to MainScaffold
            manager.startTutorialSequence(widget.showcaseContext);
            // Reset the flag in UiStateProvider
            context.read<UiStateProvider>().consumeTutorialReplayRequest();
          } catch (e) {
            print("Error restarting tutorial: $e");
            // Optionally reset the flag even if there's an error
            context.read<UiStateProvider>().consumeTutorialReplayRequest();
          }
        }
      });
    }

  }
  void _checkAndOpenDrawer() {
  final uiState = context.read<UiStateProvider>(); // Use read if not watching in build

  if (uiState.currentPageIndex == 2 && uiState.openProgramDrawerRequested) {
    // Consume the request so it doesn't happen again on rebuild
    uiState.consumeProgramDrawerRequest();

    // Important: Ensure this runs *after* the build phase is complete
    // if called during build or initState/didChangeDependencies.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Check if the state is still mounted
          //debugPrint("🏠 Opening drawer from MainScaffoldState due to request");
          _scaffoldKey.currentState?.openDrawer();
      }
    });
  }
}

  //for testing notifications
  // String notifications = "";

  void openProgramDrawer() {
      //debugPrint("🏠 openProgramDrawer() called");

    // Use the context from the State object which is a descendant of the Scaffold
    _scaffoldKey.currentState?.openDrawer();
  }

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    if (settings.isFirstTime) {
      Provider.of<TutorialManager>(context, listen: false)
          .startTutorialSequence(widget.showcaseContext); // Use the passed showcaseContext
    }
  });
}

  @override
  Widget build(BuildContext context) {
    
    final uiState = context.watch<UiStateProvider>();
    final manager = context.watch<TutorialManager>();
    //debugPrint("${manager.tutorialActive}");


    final ThemeData theme = Theme.of(context);

    // Ignore interaction during tutorial
    return IgnorePointer(
      ignoring: manager.tutorialActive,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(context),
        // floatingActionButton: TextButton(
        //   onPressed: () async {
        //     notifications = await notiService.debugPrintScheduledNotifications();
        //   }, 
        //   child: const Text("see notifs")
        // ),
      
        drawer: ProgramsDrawer(
          currentProgramId: context.read<Profile>().currentProgram.programID,
          onProgramSelected: (selectedProgram) {
            context.read<Profile>().updateProgram(selectedProgram);
          },
      
          theme: theme,
        ),
      
      
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) => uiState.currentPageIndex = index,
          indicatorColor: theme.colorScheme.primary,
          indicatorShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(12),
            ),
          ),
      
          selectedIndex: uiState.currentPageIndex,
          //different pages that can be navigated to
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: Icon(Icons.fitness_center),
              icon: Icon(Icons.fitness_center_outlined),
              label: 'Workout',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.calendar_month),
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.now_widgets_outlined),
              selectedIcon: Icon(Icons.now_widgets),
              label: 'Program',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
          ],
        ),
      
        //what opens for each page
        body: //Stack(
          //children: [
            
        <Widget>[
      
          WorkoutSelectionPage(theme: theme, key: widget.workoutPageKey),
        
          const SchedulePage(),
        
          ProgramPage(programkey: widget.programPageKey),
        
          AnalyticsPage(theme: theme),
        ][uiState.currentPageIndex],
      
        // Positioned(
        //   bottom: 100,
        //   child: Container(height: 500,
        //   color: Colors.red,
        //         child: Text(
        //           notifications,
        //           softWrap: true,
        //           maxLines: 100
                 
        //           )
        //       ),
        // ),
        //   ],
        //),
        
      
      
        bottomSheet: _buildBottomSheet(),
      //      bottomSheet: (context.watch<ActiveWorkoutProvider>().activeDay != null) ? WorkoutControlBar(theme: theme) : null,
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final uiState = context.watch<UiStateProvider>();
    final manager = context.watch<TutorialManager>();
    final theme = Theme.of(context);

    // Default
    String title = "Workout";

    if (uiState.customAppBarTitle != null){
      title = uiState.customAppBarTitle!;
    } else if (uiState.isAddingGoal){
      title = "Select Exercise For Goal";
    } else if (uiState.currentPageIndex == 1){
      title = "Schedule";
    } else if (uiState.currentPageIndex == 2){
      title = context.watch<Profile>().currentProgram.programTitle;
    } else if (uiState.currentPageIndex == 3){
      title = "Analytics";
    }

    Widget? leading = Showcase(
      disableDefaultTargetGestures: true,
      key: AppTutorialKeys.editPrograms,
      description: "Create and manage programs from here.",
      tooltipBackgroundColor: theme.colorScheme.surfaceContainerHighest,
      descTextStyle: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 16,
      ),

      tooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          onTap: () => manager.skipTutorial(),
          backgroundColor: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.onSurface
          ),
          textStyle: TextStyle(
            color: theme.colorScheme.onSurface
          )

          
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          onTap: () => manager.advanceStep(),
          border: Border.all(
            color: theme.colorScheme.onSurface
          ),
          backgroundColor: theme.colorScheme.surface,
          textStyle: TextStyle(
            color: theme.colorScheme.onSurface
          )
        )
      ],
      child: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
      ),
    );
    
    return AppBar(
        centerTitle: true,
        title: Text(
          title
        ),

        // Open Drawer to see/select/edit programs if on program page
        leading: leading,

      actions: [
        // Takes to settings page
        Showcase(
          disableDefaultTargetGestures: true,
          description: "If you want to change any settings in the future, you can find them here.",
          //disableDefaultTargetGestures: true,
          key: AppTutorialKeys.settingsButton,
          tooltipBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          descTextStyle: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),

          tooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          onTap: () => manager.skipTutorial(),
          backgroundColor: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.onSurface
          ),
          textStyle: TextStyle(
            color: theme.colorScheme.onSurface
          )

          
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          onTap: () => manager.advanceStep(),
          border: Border.all(
            color: theme.colorScheme.onSurface
          ),
          backgroundColor: theme.colorScheme.surface,
          textStyle: TextStyle(
            color: theme.colorScheme.onSurface
          )
        )
      ],

          child: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
              );
            }
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomSheet(){
    final uiState = context.watch<UiStateProvider>();
    ThemeData theme = Theme.of(context);

    // The bottom sheet should be a done button if the user is using a numeric keyboard
    // then, if on program page we should display calendar
    // then, if active workout then we display workoutstopwatch
    // otherwise display nothing 

    if (uiState.isEditing) return null;

    if (context.read<Profile>().done){ 
      return DoneButtonBottom(
        context: context,
        theme: theme,
      );
    }else{
      return Consumer<ActiveWorkoutProvider>(

        builder: (context, activeWorkout, child) {
          if (uiState.currentPageIndex == 2){
            return CalendarBottomSheet(
              today: DateTime.now(),
              theme: theme
            );
          } else if (activeWorkout.activeDay != null){
            return WorkoutControlBar(theme: theme);
          } else{
            return const SizedBox.shrink();
          }
        }
      );
    }  
  }
}
