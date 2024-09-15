// ignore_for_file: prefer_const_constructors
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_page.dart';
import 'schedule_page.dart';
import 'program_page.dart';
import 'analytics_page.dart';
import 'user.dart';
//import 'package:google_fonts/google_fonts.dart';//

/// Flutter code sample for [NavigationBar].

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp( NavigationBarApp());

}

class NavigationBarApp extends StatefulWidget {
    

  const NavigationBarApp({super.key});
  @override
  State<NavigationBarApp> createState() => _MainPage();
  //_MainPage createState() => _MainPage();
}
class _MainPage extends State<NavigationBarApp> {
  List<SplitDayData> split = 
  [SplitDayData(data: "Push", dayColor: const Color.fromRGBO(106, 92, 185, 1), ), 
  SplitDayData(data: "Pull", dayColor:  const Color.fromRGBO(150, 50, 50, 1),), 
  SplitDayData(data: "Legs", dayColor: const Color.fromRGBO(61, 101, 167, 1),)];


  late SharedPreferences _sharedPrefs;

  getSharedPreferences() async {
    //print("gotsharedprefs");
    _sharedPrefs = await SharedPreferences.getInstance();
    readPrefs();
    
  }

  writePrefs(){
    //print("wroteprefs");
    List<String> splitDataList = split.map((data) => jsonEncode(data.toJson())).toList();
    _sharedPrefs.setStringList('splitData', splitDataList);
  }

  readPrefs(){
    //print("readprefs");
    List<String>? splitDataList = _sharedPrefs.getStringList('splitData');
    if (splitDataList != null){
      split = splitDataList.map((data) => SplitDayData.fromJson(json.decode(data))).toList(growable: true);
      //rint("split");
    }
    setState((){

    });
  }

  @override

  void initState() {
    //print("initprefs");
    getSharedPreferences();
    super.initState();
  }
  //TODO: everytime split is updated, save it to shared porefrecnes.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [

        ChangeNotifierProvider(
          create: (context) => Profile(
            split: split,
            // this is temporairy while i figure out persistence for the split,
            // so that i dont run into index out of range on the excercises
            excercises: [[],[],[], [], [], [], [], [], [], [] , []],
            uuidCount: 0,
            ),
          ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.deepPurple,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          )
        ),
        //theme: ThemeData(useMaterial3: false),s
        home: NavigationExample(updater: writePrefs,),
      ),
    );
  }
}

class NavigationExample extends StatefulWidget {
  Function updater;
  NavigationExample({super.key, required this.updater});
  
  @override
  _NavigationExampleState createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;
  
  
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    //var list = ['Legs', 'Push', 'Pull'];
    //var excercises = ['Squats 3x2','Deadlifts 4x2', 'Calf Raises 5x3'];
    return Scaffold(
      resizeToAvoidBottomInset : false,
      
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.deepPurple,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
          Radius.circular(12),
          ),
        ),
        //indicatorShape:  RoundedRectangleBorder(BorderSide side = BorderSide.none, borderRadius = BorderRadius.zero),
        selectedIndex: currentPageIndex,
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
      body: <Widget>[
        /// Workout page
        WorkoutPage(),

        
        /// Schedule page
        SchedulePage(),
        /// Program page
        ProgramPage(writePrefs: widget.updater),
        ///Analyitcs page
        AnalyticsPage(theme: theme),
      ][currentPageIndex],
    );
  }
}

