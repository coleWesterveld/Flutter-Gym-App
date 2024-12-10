// ignore_for_file: prefer_const_constructors
//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


//import 'package:shared_preferences/shared_preferences.dart';
import 'workout_selection_page.dart';
import 'schedule_page.dart';
import 'program_page.dart';
import 'analytics_page.dart';
import 'user.dart';
import 'data_saving.dart';
import 'database/database_helper.dart';
import 'database/profile.dart';

/* colour choices:
my goal is to make tappable things blue
editable things orange 
simplify the design, get rid of unnessecary colours so that attention is drawn to whats important
*/
// TODO: lots of overhaul to convert all builders to future builders 
// implement copywith methods to make it easy to change just one value
// to work with database data retrieval

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  // sqfliteFfiInit();
  // databaseFactory = databaseFactoryFfi;
  runApp(NavigationBarApp());
}

Color darken(Color c, [int percent = 10]) {
  assert(1 <= percent && percent <= 100);
  var f = 1 - percent / 100;
  return Color.fromARGB(c.alpha, (c.red * f).round(), (c.green * f).round(),
      (c.blue * f).round());
}

class NavigationBarApp extends StatefulWidget {
  const NavigationBarApp({super.key});
  @override
  State<NavigationBarApp> createState() => _MainPage();
  //_MainPage createState() => _MainPage();
}

class _MainPage extends State<NavigationBarApp> {
  // Future<List<Day>> split = Future.value([]);
  // Future<List<List<Excercise>>> excercises = Future.value([]);
  // Future<List<List<List<PlannedSet>>>> sets = Future.value([]);

//  default split, gets overwridden by user choices
  // List<SplitDayData> split = [
  //   SplitDayData(
  //     data: "Push",
  //     dayColor: const Color.fromRGBO(106, 92, 185, 1),
  //   ),
  //   SplitDayData(
  //     data: "Pull",
  //     dayColor: const Color.fromRGBO(150, 50, 50, 1),
  //   ),
  //   SplitDayData(
  //     data: "Legs",
  //     dayColor: const Color.fromRGBO(61, 101, 167, 1),
  //   )
  // ];

  final dbHelper = DatabaseHelper.instance;

  //Future<List<ExpansionTileController>> controllers;

  @override
  void initState() {

    // split = dbHelper.initializeSplitList();
    // excercises = dbHelper.initializeExcerciseList();
    // sets = dbHelper.initializeSetList();
    super.initState();
  }

  // List<ExpansionTileController> setControllers() {
  //   return List<ExpansionTileController>.filled(
  //               growable: true);
  // }


  // List<ExpansionTileController>.filled(
  //               split.length, ExpansionTileController(),
  //               growable: true),

  @override
  Widget build(BuildContext context) {
    //sets =sets ;//sets;

    //provider for global variable information
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => Profile(
            dbHelper: dbHelper,
            //split: split,
            controllers: [],//setControllers()
            // this is temporairy while i figure out persistence for the split,
            // so that i dont run into index out of range on the excercises
            //with sets this is atrocious lol
            //excercises: excercises,

            //sets: sets,

            reps1TEC: [],
            reps2TEC: [],
            rpeTEC: [],
            setsTEC: [],

          ),
        ),
      ],
      child: MaterialApp(
        title: 'TempTitle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            snackBarTheme: SnackBarThemeData(
              backgroundColor: Color(0xFFF28500),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(
                  0XFF1C1C1C), //darken(Color.fromARGB(255, 12, 74, 151),60),
              brightness: Brightness.dark,
            )),
        //theme: ThemeData(useMaterial3: false),s
        home: NavigationExample(
          dbHelper: dbHelper,
          //updater: writePrefs,
        ),
      ),
    );
  }
}

class NavigationExample extends StatefulWidget {
  //Function updater;
  final DatabaseHelper dbHelper;
  const  NavigationExample({super.key, required this.dbHelper,/*required this.updater*/});

  @override
  NavigationExampleState createState() => NavigationExampleState();
}

class NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;

  void changeColor(Color newColor, int index) =>
      setState(() => context.watch<Profile>().splitAssign(
        newDay: context.watch<Profile>().split[index].copyWith(newDayColor: newColor.value), 
        index: index,
        ));
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    //var list = ['Legs', 'Push', 'Pull'];
    //var excercises = ['Squats 3x2','Deadlifts 4x2', 'Calf Raises 5x3'];
    return Scaffold(
      resizeToAvoidBottomInset: true,

      bottomNavigationBar: NavigationBar(
        //backgroundColor: Color(0xFF643f00),
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Color(0XFF1A78EB),
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
            icon: Badge(child: Icon(Icons.calendar_month_outlined)),
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
        /// Workout page
        WorkoutPage(),

        /// Schedule page
        SchedulePage(),

        /// Program page
        ProgramPage(
          dbHelper: widget.dbHelper,
          // writePrefs: widget.updater,
        ),

        ///Analyitcs page
        AnalyticsPage(theme: theme),
      ][currentPageIndex],
    );
  }
}