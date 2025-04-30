import 'package:flutter/material.dart';
//import 'data_saving.dart';
import '../database/database_helper.dart';
import '../database/profile.dart';
  // import 'dart:math';
  import 'dart:async';
  import '../../other_utilities/day_of_week.dart';
import 'package:firstapp/providers_and_settings/program_provider.dart';

//import 'dart:math';
// programProvider.split, programProvider.sets, etc in provider
// on opening app, set programProvider.split data and other data to whatever is in database
// database is initialized with values but is then changed by user
// give that programProvider.split to provider
// whenever data is changed, update database in provider asynchronously
// whenever we retrieve data from provider, we now have to user futurebuilder

// A lot of the database functionality here could maybe be double checked...

// okay, im gonna try breaking this up into a few different Providers
//

class ActiveWorkoutProvider extends ChangeNotifier {

  // We need ActiveWorkoutProvider to have access to program providers members
  Profile programProvider;

  // I am trying to also make TEC's for the workout page
  List<List<List<TextEditingController>>> workoutRpeTEC;
  List<List<List<TextEditingController>>> workoutWeightTEC;
  List<List<List<TextEditingController>>> workoutRepsTEC;
  List<TextEditingController> workoutNotesTEC;
  List<ExpansionTileController> workoutExpansionControllers;

  DatabaseHelper dbHelper;
  int? activeDayIndex;
  Day? activeDay;
  List<bool>? showHistory;
  List<int> nextSet = [0, 0, 0];

  final Stopwatch workoutStopwatch = Stopwatch();
  final Stopwatch restStopwatch = Stopwatch();
  Timer? timer;
  bool isPaused = false;
  String? sessionID;
  bool shakeFinish = false;


  ActiveWorkoutProvider({
    this.workoutNotesTEC = const <TextEditingController>[],
    this.workoutRepsTEC = const <List<List<TextEditingController>>>[],
    this.workoutRpeTEC = const <List<List<TextEditingController>>>[],
    this.workoutWeightTEC = const <List<List<TextEditingController>>>[],
    this.workoutExpansionControllers = const <ExpansionTileController>[],
    
    required this.dbHelper,
    required this.programProvider,
    this.activeDayIndex,
    this.activeDay,
    this.showHistory,
  }){
    _init();
  }

  Future<void> _init() async {
    // TODO: I think these need to be disposed first, memory is leaking
    workoutNotesTEC.clear();
    workoutRepsTEC.clear();
    workoutRpeTEC.clear();
    workoutWeightTEC.clear();
    notifyListeners();
  }

  // Call this from `update:` or a listener:
  void syncControllersForDay(int dayIndex) {
    final exercisesForDay = programProvider.exercises[dayIndex];
    final plannedSetsForDay = programProvider.sets[dayIndex];
    final int numExercises = exercisesForDay.length;

    // 1) Outer-list: one sublist per exercise
    _ensureLength(workoutRpeTEC,    numExercises, () => <List<TextEditingController>>[]);
    _ensureLength(workoutWeightTEC, numExercises, () => <List<TextEditingController>>[]);
    _ensureLength(workoutRepsTEC,   numExercises, () => <List<TextEditingController>>[]);
    _ensureLength(workoutExpansionControllers, numExercises, () => ExpansionTileController());
    //_ensureLength(workoutNotesTEC, numExercises, () => TextEditingController());


    // 2) Middle-list: one sublist per PlannedSet in each exercise
    for (int i = 0; i < numExercises; i++) {
      final setsForExercise = plannedSetsForDay[i];
      final int numSetEntries = setsForExercise.length;

      _ensureLength(workoutRpeTEC[i],    numSetEntries, () => <TextEditingController>[]);
      _ensureLength(workoutWeightTEC[i], numSetEntries, () => <TextEditingController>[]);
      _ensureLength(workoutRepsTEC[i],   numSetEntries, () => <TextEditingController>[]);
    }

    // 3) Inner-list: one controller _per_ plannedSet.numSets
    for (int i = 0; i < numExercises; i++) {
      for (int j = 0; j < plannedSetsForDay[i].length; j++) {
        final int slots = plannedSetsForDay[i][j].numSets;

        _ensureLength(workoutRpeTEC[i][j],    slots, () => TextEditingController());
        _ensureLength(workoutWeightTEC[i][j], slots, () => TextEditingController());
        _ensureLength(workoutRepsTEC[i][j],   slots, () => TextEditingController());
      }
    }

    // 4) Notes and expansion controllers—one per exercise
    _ensureLength(workoutNotesTEC, numExercises, () => TextEditingController());
  }

  // Utility to grow/shrink a List<T>, disposing controllers if needed
  void _ensureLength<T>(List<T> list, int targetLen, T Function() make) {
    // grow
    while (list.length < targetLen) {
      list.add(make());
    }
    // shrink
    while (list.length > targetLen) {
      final removed = list.removeLast();
      if (removed is TextEditingController)    removed.dispose();
      //if (removed is ExpansionTileController)  removed.dispose();
      // if it’s a List<…> you’ll eventually hit inner controllers which
      // will be disposed by their own ensureLength calls
    }
  }

  void togglePause() {
  
    isPaused = !isPaused;
    if (isPaused) {
      workoutStopwatch.stop();
      restStopwatch.stop();
    } else {
      workoutStopwatch.start();
      restStopwatch.start();
    }
    notifyListeners();
    // TODO: persist in DB
    //_saveWorkoutState();
  }

  void startTimers() {
    debugPrint("started!");
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused) {
        notifyListeners(); // This makes the UI update
      }
    });

    restStopwatch.start();
    workoutStopwatch.start();
    notifyListeners();
  }

  String generateWorkoutSessionId() {
    final now = DateTime.now();
    // Convert the current time to an ISO8601 string.
    final timestamp = now.toIso8601String(); // e.g. "2025-03-16T14:22:31.123"
    startTimers();
    

    sessionID = timestamp;
    return timestamp;
  }

    // programProvider.sets whatever day the user is currently doing
  void setActiveDay(int? index){

    if ((index != null && index >= 0 && index < programProvider.split.length)){

      activeDayIndex = index;
      activeDay = programProvider.split[index];
      showHistory = List.filled(programProvider.exercises[index].length, false);
      workoutNotesTEC = List.generate(growable: true, programProvider.exercises[index].length,  (_) => TextEditingController());
      
      workoutRepsTEC = List.generate(
        growable: true, 
        programProvider.exercises[index].length,  
        (int idx) => List.generate(
          programProvider.sets[index][idx].length, 
          (setIndex) => List.generate(
            programProvider.sets[index][idx][setIndex].numSets, 
            (subSetIndex) => TextEditingController()
          )
        )
      );

      workoutRpeTEC = List.generate(
        growable: true, 
        programProvider.exercises[index].length,  
        (int idx) => List.generate(
          programProvider.sets[index][idx].length,
          (setIndex) => List.generate(
            programProvider.sets[index][idx][setIndex].numSets, 
            (subSetIndex) => TextEditingController()
          )
        )
      );

      workoutWeightTEC = List.generate(
        growable: true, 
        programProvider.exercises[index].length,  
        (int idx) => List.generate(
          programProvider.sets[index][idx].length, 
          (setIndex) => List.generate(
            programProvider.sets[index][idx][setIndex].numSets, 
            (subSetIndex) => TextEditingController()
          )
        )
      );

      workoutExpansionControllers = List.generate(
        growable: true, 
        programProvider.exercises[index].length,  
        (_) => ExpansionTileController()
      );
    }else{
      activeDayIndex = null;
      activeDay = null;
      showHistory = null;
      // TODO: I think I should dispose first
      workoutWeightTEC.clear();
      workoutNotesTEC.clear();
      workoutRepsTEC.clear();
      workoutRpeTEC.clear();
      workoutExpansionControllers.clear();
    }
    
    notifyListeners();
  }

    void incrementSet(List<int> justDone) {
    assert(activeDayIndex != null, "Trying to set an active set while no workout is in progress");
    assert(justDone.length == 3, "justDone should be [exerciseIndex, setIndex, subsetIndex]");

    final currentExerciseIndex = justDone[0];
    final currentSetIndex = justDone[1];
    final currentSubsetIndex = justDone[2];
    final currentSet = programProvider.sets[activeDayIndex!][currentExerciseIndex][currentSetIndex];

    // Check if there are more subsets in current set
    if (currentSubsetIndex < currentSet.numSets - 1) {
      // Move to next subset in same set
      nextSet = [currentExerciseIndex, currentSetIndex, currentSubsetIndex + 1];
    } 
    // Check if there are more sets in current exercise
    else if (currentSetIndex < programProvider.sets[activeDayIndex!][currentExerciseIndex].length - 1) {
      // Move to first subset of next set in same exercise
      nextSet = [currentExerciseIndex, currentSetIndex + 1, 0];
    } 
    // Check if there are more exercises in workout
    else if (currentExerciseIndex < programProvider.exercises[activeDayIndex!].length - 1) {
      // Move to first subset of first set in next exercise
      nextSet = [currentExerciseIndex + 1, 0, 0];
    }
    // Else we're at the end of the workout
    else {
      // Optionally handle workout completion here
      shakeFinish = true;
      // Keep nextSet pointing to last subset
      nextSet = [currentExerciseIndex, currentSetIndex, currentSubsetIndex];
    }

    notifyListeners();
  }
}