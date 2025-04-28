// Holds the keys of widgets to be referenced in the tutorial/walkthrough that runs on startup

import 'package:flutter/material.dart';

class AppTutorialKeys {
  // These will show after the user is presented option to set settings
  // But then we will show them where to find settings in the future
  static final GlobalKey tutorialStartButton = GlobalKey();

  // 1st - Settings
  static final GlobalKey settingsButton = GlobalKey();       // On program page

  // 2nd - Program Page
  static final GlobalKey editPrograms = GlobalKey();           // On program page - in drawer
  static final GlobalKey addDayToProgram = GlobalKey();      // On program page
  static final GlobalKey addExerciseToProgram = GlobalKey(); // On program page - under expansion tile
  static final GlobalKey addSetsToExercise = GlobalKey();    // Same as ^

  // 3rd - Schedule Page
  static final GlobalKey schedule = GlobalKey();
  static final GlobalKey editScheduleButton = GlobalKey();
  static final GlobalKey editScheduleDragNDrop = GlobalKey();

  // 4th - Workout
  static final GlobalKey startWorkout = GlobalKey();
  static final GlobalKey logASet = GlobalKey();
  static final GlobalKey seeHistory = GlobalKey();

  // 5th - Analytics
  static final GlobalKey searchAnalytics = GlobalKey();
  static final GlobalKey recentWorkouts = GlobalKey();
  static final GlobalKey addGoals = GlobalKey();
  
  static List<GlobalKey> getAllKeys() => [
    settingsButton,
    editPrograms,
    addDayToProgram,
    addExerciseToProgram,
    //schedule,
    editScheduleButton,
    // editScheduleDragNDrop,
    startWorkout,
    // logASet,
    // seeHistory,
    // searchAnalytics,
    // recentWorkouts,
    // addGoals
  ];
}