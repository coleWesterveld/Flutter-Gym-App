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
  final BuildContext showcaseContext; // Receive the showcase context


  MainScaffold({super.key, this.workoutPageKey, required this.showcaseContext});

  @override
  MainScaffoldState createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  int currentPageIndex = 2;

  //for testing notifications
  // String notifications = "";

  @override
  void initState() {
    super.initState();
    // Start the tutorial sequence after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // Access TutorialManager and start the sequence using the correct context
       Provider.of<TutorialManager>(context, listen: false)
            .startTutorialSequence(widget.showcaseContext); // Use the passed showcaseContext
    });
  }

  // For automatic page switching - used in tutorial
  void changePage(int index) {
     if (mounted && index != currentPageIndex) { // Check if mounted
        setState(() {
          currentPageIndex = index;
        });
     }
  }

  @override
  Widget build(BuildContext context) {


    final ThemeData theme = Theme.of(context);

    return Scaffold(
      // floatingActionButton: TextButton(
      //   onPressed: () async {
      //     notifications = await notiService.debugPrintScheduledNotifications();
      //   }, 
      //   child: const Text("see notifs")
      // ),


      resizeToAvoidBottomInset: true,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) => changePage(index),
        indicatorColor: theme.colorScheme.primary,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
        ),

        selectedIndex: currentPageIndex,
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
      
        ProgramPage(),
      
        AnalyticsPage(theme: theme),
      ][currentPageIndex],

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
      


      bottomSheet: Consumer<ActiveWorkoutProvider>(
      builder: (context, activeWorkout, child) {
        if (activeWorkout.activeDay != null){
          return WorkoutControlBar(theme: theme);
        } else{
          return const SizedBox.shrink();
        }
      },
      // Pass the potentially expensive body (page switcher) as the child
      // child: IndexedStack(...) or YourPageSwitcherWidget(),
      // --> Or keep the simple page list if performance is okay there:
      // child: <Widget>[ ... AnalyticsPage ... ][currentPageIndex],
    ),
//      bottomSheet: (context.watch<ActiveWorkoutProvider>().activeDay != null) ? WorkoutControlBar(theme: theme) : null,
    );
  }
}
