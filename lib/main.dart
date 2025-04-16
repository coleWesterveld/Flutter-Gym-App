import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Pages
import 'package:firstapp/workout_page/workout_selection_page.dart';       // Workout Selector
import 'package:firstapp/schedule_page/schedule_page.dart';               // Schedule Page
import 'package:firstapp/program_page/program_page.dart';                 // Program Creator
import 'package:firstapp/analytics_page/analytics_page.dart';             // Analytics Page

// Utilities
import 'package:firstapp/database/database_helper.dart';                  // Database Methods
import 'package:firstapp/other_utilities/workout_stopwatch.dart';         // Active Workout Clock
import 'package:firstapp/providers_and_settings/program_provider.dart';   // Program Management
import 'package:firstapp/providers_and_settings/settings_provider.dart';  // Settings
import 'package:firstapp/theme/app_theme.dart';                           // Theme

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
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymApp());
}

class GymApp extends StatefulWidget {
  const GymApp({super.key});
  @override
  State<GymApp> createState() => _MainPage();
}

class _MainPage extends State<GymApp> {

  final dbHelper = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SettingsModel()
        ),


        ChangeNotifierProvider(
          // this got a bit big and should probably be split into maybe 2 or more providers
          create: (context) => Profile(
            dbHelper: dbHelper,
            controllers: [],
            reps1TEC: [],
            reps2TEC: [],
            rpeTEC: [],
            setsTEC: [],
            workoutNotesTEC: [],
            workoutRepsTEC: [],
            workoutRpeTEC: [],
            workoutWeightTEC: [],
            workoutExpansionControllers: []
          ),
        ),
      ],
      child: MaterialApp(
        title: 'TempTitle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme, // Apply the dark theme by default
        // themeMode: settings.themeMode, // If you implement theme switching via SettingsModel
        // darkTheme: AppTheme.darkTheme,
        // lightTheme: AppTheme.lightTheme, // Define lightTheme similarly if needed
        home: MainScaffold(
          dbHelper: dbHelper,
        ),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  //Function updater;
  final DatabaseHelper dbHelper;
  const  MainScaffold({super.key, required this.dbHelper,});

  @override
  MainScaffoldState createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },

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
      body: <Widget>[

        WorkoutSelectionPage(theme: theme),

        SchedulePage(theme: theme),

        ProgramPage(
          dbHelper: widget.dbHelper,
          theme: theme
        ),

        AnalyticsPage(theme: theme),
      ][currentPageIndex],

      bottomSheet: (context.watch<Profile>().activeDay != null) ? WorkoutControlBar(theme: theme) : null,
    );
  }
}
