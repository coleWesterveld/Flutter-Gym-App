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
import 'package:firstapp/widgets/workout_stopwatch.dart';         // Active Workout Clock
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
      ],
      child: MaterialApp(
        title: 'TempTitle',
        debugShowCheckedModeBanner: false,
        //theme: AppTheme.lightTheme, // Apply the dark theme by default
        themeMode: ThemeMode.system, // If you implement theme switching via SettingsModel
        darkTheme: AppTheme.darkTheme,
        theme: AppTheme.lightTheme, // Define lightTheme similarly if needed
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
