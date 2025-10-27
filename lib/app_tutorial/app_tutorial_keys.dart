// Holds the keys of widgets to be referenced in the tutorial/walkthrough that runs on startup

import 'package:flutter/material.dart';

class AppTutorialKeys {
  // These will show after the user is presented option to set settings
  // But then we will show them where to find settings in the future
  static final GlobalKey tutorialStartButton = LabeledGlobalKey('tutorialStartButton');

  // 1st - Settings
  static final GlobalKey settingsButton = LabeledGlobalKey('settingsButton');       // On program page

  // 2nd - Program Page
  static final GlobalKey editPrograms = LabeledGlobalKey('editPrograms');           // On program page - in drawer
  static final GlobalKey addDayToProgram = LabeledGlobalKey('addDayToProgram');      // On program page
  // Tutorial-specific variant to avoid collisions with app tree
  static final GlobalKey addDayToProgramTutorial = LabeledGlobalKey('addDayToProgram_tutorial');
  static final GlobalKey addExerciseToProgram = LabeledGlobalKey('addExerciseToProgram'); // On program page - under expansion tile
  static final GlobalKey addSetsToExercise = LabeledGlobalKey('addSetsToExercise');    // Same as ^

  // 3rd - Schedule Page
  static final GlobalKey schedule = LabeledGlobalKey('schedule');
  static final GlobalKey editScheduleButton = LabeledGlobalKey('editScheduleButton');
  static final GlobalKey editScheduleDragNDrop = LabeledGlobalKey('editScheduleDragNDrop');

  // 4th - Workout
  static final GlobalKey startWorkout = LabeledGlobalKey('startWorkout');
  static final GlobalKey logASet = LabeledGlobalKey('logASet');
  static final GlobalKey seeHistory = LabeledGlobalKey('seeHistory');

  // 5th - Analytics
  static final GlobalKey searchAnalytics = LabeledGlobalKey('searchAnalytics');
  static final GlobalKey recentWorkouts = LabeledGlobalKey('recentWorkouts');
  static final GlobalKey addGoals = LabeledGlobalKey('addGoals');
  
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