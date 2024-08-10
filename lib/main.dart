// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'workout_page.dart';
import 'schedule_page.dart';
import 'program_page.dart';
import 'analytics_page.dart';
//import 'package:google_fonts/google_fonts.dart';//

/// Flutter code sample for [NavigationBar].

void main() => runApp( NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  NavigationBarApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        )
      ),
      //theme: ThemeData(useMaterial3: false),s
      home: NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  NavigationExample({super.key});
  
  @override
  State<NavigationExample> createState() => _NavigationExampleState();
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
        ProgramPage(),
        ///Analyitcs page
        AnalyticsPage(theme: theme),
      ][currentPageIndex],
    );
  }
}

