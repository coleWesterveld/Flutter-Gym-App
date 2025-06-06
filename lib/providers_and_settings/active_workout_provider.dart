import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'data_saving.dart';
import '../database/database_helper.dart';
import '../database/profile.dart';
  // import 'dart:math';
import 'dart:async';
import 'package:firstapp/providers_and_settings/program_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving state
import 'dart:convert'; // For jsonEncode/jsonDecode
import 'package:firstapp/providers_and_settings/snapshot_active_workout.dart';

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

  // this helps track the expansion states, SPECIFICALLY when for the device disconnects and the expansion tiles linked with the controllers will have been disposed
  List<bool> expansionStates;

  DatabaseHelper dbHelper;
  int? activeDayIndex;
  Day? activeDay;
  List<bool>? showHistory = <bool>[];
  List<int> nextSet = [0, 0, 0];
  List<bool> isExerciseComplete = [];

  DateTime? workoutStartTime;
  DateTime? lastRestStartTime;
  Timer? timer;
  bool isPaused = false;
  String? sessionID;
  bool shakeFinish = false;

  // versioned by Json structure, in case updates come
  static const String _snapshotKey = 'activeWorkoutSnapshot_v1';

  Duration get workoutTime { 
    if (workoutStartTime != null){
      final diff = DateTime.now().difference(workoutStartTime!);

      return diff;
    } else{
      debugPrint("WARN: this should not happen -- workout start time is trying to be read but it is Null");
    }
    
    // no duration
    return const Duration();
  }

    Duration get restTime { 
    if (lastRestStartTime != null){
      final diff = DateTime.now().difference(lastRestStartTime!);

      return diff;
    } else{
      debugPrint("WARN: this should not happen -- rest start time is trying to be read but it is Null");
    }
    
    // no duration
    return const Duration();
  }

  ActiveWorkoutProvider({
    this.workoutNotesTEC = const <TextEditingController>[],
    this.workoutRepsTEC = const <List<List<TextEditingController>>>[],
    this.workoutRpeTEC = const <List<List<TextEditingController>>>[],
    this.workoutWeightTEC = const <List<List<TextEditingController>>>[],
    this.workoutExpansionControllers = const <ExpansionTileController>[],
    this.expansionStates = const <bool>[],
    
    required this.dbHelper,
    required this.programProvider,
    this.activeDayIndex,
    this.activeDay,
    this.showHistory,
  });

  // Future<void> _init() async {
  //   // TODO: I think these need to be disposed first, memory is leaking
  //   workoutNotesTEC.clear();
  //   workoutRepsTEC.clear();
  //   workoutRpeTEC.clear();
  //   workoutWeightTEC.clear();
  //   notifyListeners();
  // }

  @override
  void dispose() {
    timer?.cancel();
    _disposeAllTECs();
    super.dispose();
  }

  // Dispose all TECs properly
  void _disposeAllTECs() {
    for (var list2D in workoutRpeTEC) { for (var list1D in list2D) { for (var tec in list1D) { tec.dispose(); } } }
    for (var list2D in workoutWeightTEC) { for (var list1D in list2D) { for (var tec in list1D) { tec.dispose(); } } }
    for (var list2D in workoutRepsTEC) { for (var list1D in list2D) { for (var tec in list1D) { tec.dispose(); } } }
    for (var tec in workoutNotesTEC) { tec.dispose(); }
    // ExpansionTileControllers might not need explicit dispose unless they hold resources
    workoutRpeTEC = [];
    workoutWeightTEC = [];
    workoutRepsTEC = [];
    workoutNotesTEC = [];
    workoutExpansionControllers = []; // Resetting lists
    expansionStates = [];
  }

  Future<void> saveActiveWorkoutState() async {
    debugPrint("hey this should run for sure");
    if (sessionID == null || activeDayIndex == null) {
      debugPrint("1.1 hey this should run for sure");
      await clearActiveWorkoutState(); // Clear if no active session
      return;
    }
    debugPrint("1.2 hey this should run for sure");


    Map<String, String> currentTecValues = {};
    for (int i = 0; i < workoutNotesTEC.length; i++) {
      currentTecValues['e${i}_notes'] = workoutNotesTEC[i].text;
    }
    for (int i = 0; i < workoutRpeTEC.length; i++) {
      for (int j = 0; j < workoutRpeTEC[i].length; j++) {
        for (int k = 0; k < workoutRpeTEC[i][j].length; k++) {
          currentTecValues['e${i}_s${j}_m${k}_rpe'] = workoutRpeTEC[i][j][k].text;
          currentTecValues['e${i}_s${j}_m${k}_weight'] = workoutWeightTEC[i][j][k].text;
          currentTecValues['e${i}_s${j}_m${k}_reps'] = workoutRepsTEC[i][j][k].text;
        }
      }
    }
    debugPrint("1.3 hey this should run for sure");


    //List<bool> currentExpansionStates = expansionStates.map((c) => c.isExpanded).toList();

    debugPrint("1.4 hey this should run for sure");

  List<List<List<int?>>>? currentLoggedRecordIDs;
  if (activeDayIndex != null &&
      activeDayIndex! < programProvider.sets.length) {
    final List<List<PlannedSet>> setsForActiveDay = programProvider.sets[activeDayIndex!];
    currentLoggedRecordIDs = []; // Initialize as empty list
    for (int i = 0; i < setsForActiveDay.length; i++) { // Exercise index
      final List<PlannedSet> setGroupsForExercise = setsForActiveDay[i];
      List<List<int?>> exerciseLoggedIDs = [];
      for (int j = 0; j < setGroupsForExercise.length; j++) { // Set group index
        final PlannedSet plannedSet = setGroupsForExercise[j];
        // Create a new list from plannedSet.loggedRecordID to ensure it's serializable
        // and to avoid potential issues if the original list is modified elsewhere.
        exerciseLoggedIDs.add(List<int?>.from(plannedSet.loggedRecordID));
      }
      currentLoggedRecordIDs.add(exerciseLoggedIDs);
    }
  } else {
    debugPrint("WARN: Could not save loggedRecordIDs. activeDayIndex is null or out of bounds for programProvider.sets, or sets not loaded.");
  }

    final snapshot = ActiveWorkoutSnapshot(
      sessionID: sessionID!,
      activeDayIndex: activeDayIndex!,
      // activeProgramID: programProvider.activeProgramId, // IMPORTANT: You'll need a way to get this
      nextSet: nextSet,
      startWorkoutTime: workoutStartTime ?? DateTime.now(),
      stopwatchIsRunning: !isPaused,
      startRestTime: lastRestStartTime ?? DateTime.now(),
      tecValues: currentTecValues,
      exerciseExpansionStates: expansionStates,
      loggedRecordIDs: currentLoggedRecordIDs,
    );

    debugPrint("2 hey this should run for sure");


    final prefs = await SharedPreferences.getInstance();
    debugPrint("3 hey this should run for sure");

    try {
      final jsonString = jsonEncode(snapshot.toJson());
      await prefs.setString(_snapshotKey, jsonString);
      debugPrint('Active workout state SAVED. Session: $sessionID. Key: $_snapshotKey');
    } catch (e) {
      debugPrint('Error saving workout state: $e');
    }
  }

  Future<ActiveWorkoutSnapshot?> loadActiveWorkoutState() async {
    final prefs = await SharedPreferences.getInstance();
    final String? snapshotString = prefs.getString(_snapshotKey);
    //debugPrint("string is raw here: ${snapshotString}");
    if (snapshotString != null) {
      try {
        final snapshot = ActiveWorkoutSnapshot.fromJson(jsonDecode(snapshotString));
        debugPrint('Saved workout state loaded for session: ${snapshot.sessionID}');
        return snapshot;
      } catch (e) {
        debugPrint('Error decoding snapshot: $e. Clearing invalid snapshot.');
        await clearActiveWorkoutState();
        return null;
      }
    }
    //debugPrint('No saved workout state found.');
    return null;
  }

  Future<void> clearActiveWorkoutState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotKey);
    //debugPrint('Cleared active workout state from SharedPreferences.');
  }

  // Add this method to your ActiveWorkoutProvider class

  /// Sets the active day index and initializes the necessary empty controller structures
  /// (TECs, ExpansionTileControllers, etc.) for that day.
  /// This is called BEFORE restoring values from a snapshot.
  /// It relies on `programProvider` (Profile) having loaded its data for `dayIdx`.
  bool prepareStructuresForRestoredDay(int dayIdx) {
    // Critical check: Ensure Profile provider's data for this day is available.
    // programProvider.split refers to Profile.split
    if (dayIdx < 0 || dayIdx >= programProvider.split.length) {
      debugPrint("AWP: Cannot prepare structures. Invalid dayIndex ($dayIdx) or Profile.split not populated for it.");
      return false;
    }
    // It's also crucial that programProvider.exercises[dayIdx] and programProvider.sets[dayIdx] are populated.
    // This should be true if Profile.init() has completed and dayIdx is valid.

    debugPrint("AWP: Preparing structures for restored day index: $dayIdx");

    // Set the activeDayIndex within ActiveWorkoutProvider
    activeDayIndex = dayIdx;
    // activeDay will be set within _initializeStructuresForDay based on this new activeDayIndex

    // Call your existing method that creates all the empty TECs and controllers
    // _initializeStructuresForDay will handle disposing old ones and creating new ones.
    _initializeStructuresForDay(dayIdx);

    return true; // Structures are now ready (empty but correctly sized)
  }

  // Call this method AFTER Profile provider has loaded its data and set the active day
  // based on snapshot.activeDayIndex (and possibly snapshot.activeProgramID).
  Future<bool> restoreFromSnapshot(ActiveWorkoutSnapshot snapshot) async {
    debugPrint("Attempting to restore from snapshot for session: ${snapshot.sessionID}");
    // 1. Basic State Restoration
    sessionID = snapshot.sessionID; // Crucial: set this first
    activeDayIndex = snapshot.activeDayIndex;
    workoutStartTime = snapshot.startWorkoutTime;
    lastRestStartTime = snapshot.startRestTime;
    // Ensure programProvider has loaded the correct program and day.
    // This often means ProfileProvider.setActiveDay(snapshot.activeDayIndex) should have been called by now.
    // And this ActiveWorkoutProvider should re-initialize its TEC structures for that day.

    // Re-initialize TECs and controllers for the specific day.
    // This will create empty controllers with the correct structure.
    // `setActiveDay` already does this, but we need to ensure it's for the snapshot's day.
    // If programProvider.split is not populated for the activeDayIndex, this will fail.
    if (activeDayIndex == null || activeDayIndex! >= programProvider.split.length) {
        debugPrint("Cannot restore: activeDayIndex from snapshot is invalid for current program data.");
        await clearActiveWorkoutState(); // Clear bad snapshot
        return false;
    }
    // Call the part of setActiveDay that initializes structures
    // _initializeStructuresForDay(activeDayIndex!); // NEW helper method
    // 2. Restore TEC Values
    snapshot.tecValues.forEach((key, value) {
      final parts = key.split('_');
      final fieldType = parts.last;
      final indices = parts
          .sublist(0, parts.length - 1)
          .map((p) => int.tryParse(p.substring(1)))
          .where((item) => item != null)
          .cast<int>()
          .toList();

      try {
        
        if (fieldType == 'notes' && indices.length == 1) {
          debugPrint("adding $value to notes");
          int i = indices[0];
          if (i < workoutNotesTEC.length) workoutNotesTEC[i].text = value;
        } else if (indices.length == 3) {
          int i = indices[0], j = indices[1], k = indices[2];
          if (i < workoutRpeTEC.length &&
              j < workoutRpeTEC[i].length &&
              k < workoutRpeTEC[i][j].length) { // Check bounds carefully
            if (fieldType == 'rpe') {
              debugPrint("adding $value to rpe");

              workoutRpeTEC[i][j][k].text = value;
            } else if (fieldType == 'weight') {
              debugPrint("adding $value to weight");

              workoutWeightTEC[i][j][k].text = value;
            }
            else if (fieldType == 'reps') {
              debugPrint("adding $value to reps");

              workoutRepsTEC[i][j][k].text = value;
            }
          } else {
             debugPrint("Warning: TEC indices out of bounds during restore for key $key");
          }
        }

        if (snapshot.loggedRecordIDs != null && activeDayIndex != null &&
            activeDayIndex! < programProvider.sets.length) {
          final List<List<PlannedSet>> setsForActiveDay = programProvider.sets[activeDayIndex!];
          final List<List<List<int?>>> savedLoggedIDs = snapshot.loggedRecordIDs!;

          if (setsForActiveDay.length == savedLoggedIDs.length) {
            for (int i = 0; i < savedLoggedIDs.length; i++) { // Exercise index
              if (i < setsForActiveDay.length) {
                final List<PlannedSet> setGroupsForExercise = setsForActiveDay[i];
                final List<List<int?>> savedExerciseLoggedIDs = savedLoggedIDs[i];

                if (setGroupsForExercise.length == savedExerciseLoggedIDs.length) {
                  for (int j = 0; j < savedExerciseLoggedIDs.length; j++) { // Set group index
                    if (j < setGroupsForExercise.length) {
                      final PlannedSet plannedSetToUpdate = setGroupsForExercise[j];
                      final List<int?> idsToRestore = savedExerciseLoggedIDs[j];

                      // Ensure lengths match, or handle appropriately
                      if (plannedSetToUpdate.numSets == idsToRestore.length) {
                        plannedSetToUpdate.loggedRecordID = List<int?>.from(idsToRestore); // Direct assignment
                      } else {
                        // Handle mismatch: pad with nulls or truncate, based on current numSets
                        plannedSetToUpdate.loggedRecordID = List.filled(plannedSetToUpdate.numSets, null);
                        for (int k = 0; k < idsToRestore.length && k < plannedSetToUpdate.numSets; k++) {
                          plannedSetToUpdate.loggedRecordID[k] = idsToRestore[k];
                        }
                        debugPrint("WARN: LoggedRecordID length mismatch for e$i,s$j. Saved: ${idsToRestore.length}, Current: ${plannedSetToUpdate.numSets}. Adjusted.");
                      }
                    }
                  }
                } else { debugPrint("num sets mismatch"); }
              }
            }
            debugPrint("LoggedRecordIDs restored by direct modification.");
          } else { debugPrint("num exercises mismatch"); }
        }
      } catch (e) {
         debugPrint("Error restoring TEC for key $key: $e");
      }
    });

    isPaused = !snapshot.stopwatchIsRunning; // Set paused state
    if (snapshot.stopwatchIsRunning) {
      isPaused = false;
      // Restart the UI timer if it was running
      if (timer == null || !timer!.isActive) {
          startTimers(); // A new method to only start UI timer if not paused
      }
    } else {
      isPaused = true;
      timer?.cancel();
    }


    // 4. Restore _nextSet
    nextSet = List<int>.from(snapshot.nextSet);

    // 5. Restore Expansion Tile States
    if (snapshot.exerciseExpansionStates != null &&
        snapshot.exerciseExpansionStates!.length == workoutExpansionControllers.length) {
      
      for (int i = 0; i < workoutExpansionControllers.length; i++) {
        if (snapshot.exerciseExpansionStates![i]) {
          expansionStates[i] = true;
        } else if (!snapshot.exerciseExpansionStates![i]) {
           expansionStates[i] = false;
        }
      }
    }
    
    activeDay = programProvider.split[activeDayIndex!]; // Ensure activeDay is also set
    showHistory = List.filled(programProvider.exercises[activeDayIndex!].length, false, growable: true); // Re-init showHistory if needed
    _calculateExerciseCompletion();
    notifyListeners();
    //debugPrint("Active workout state fully restored from snapshot.");
    return true;
  }

  void _calculateExerciseCompletion(){
    // determines which exercises to mark as 'complete' based on if all sets for that exercise are compeleted
    if (activeDayIndex == null){
      debugPrint("WARN: invalid call of calculating exercise state when no workout active.");
      return;

    } else{
      // for each exercise
      for (int exerciseIndex = 0; exerciseIndex < programProvider.exercises[activeDayIndex!].length; exerciseIndex++){
        bool complete = true;
        
        // for each set cluster in each exercise
        setLoop:
        for (int setIndex = 0; setIndex < programProvider.sets[activeDayIndex!][exerciseIndex].length; setIndex++){
        
          // for each subset of each set cluster
          for (int? subSet in programProvider.sets[activeDayIndex!][exerciseIndex][setIndex].loggedRecordID){
            // if any of them are unlogged, we break out and check next exercise.
            if (subSet == null){
              complete = false;
              break setLoop;
            }
          }
        }

        isExerciseComplete[exerciseIndex] = complete;
      }

    }


  }

  // Helper to start UI timer based on current pause state
  void startTimers() {
    timer?.cancel(); // Ensure no multiple timers
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused) { // isPaused should be correctly set from snapshot
        notifyListeners();
      } else{
        // Okay this is kinda a strange solution that I came up with
        // we get the length of the workout as the duration between now and when the workout started
        // but then pause doesnt work
        // so for every second we are paused, we just move the workout start time forward,
        // so that the distance between now and the start time (the workout and rest duration) dont change 
        //  -- they are "paused" (they both move at the same speed)

        // these *shouldnt* be null, but yk, just in case
        if (workoutStartTime != null){
          workoutStartTime = workoutStartTime!.add(const Duration(seconds: 1));
        }
        if (lastRestStartTime != null){
          lastRestStartTime = lastRestStartTime!.add(const Duration(seconds: 1));
        }
        notifyListeners();
      }
    });
  }

  // Helper to initialize structures for a day (called by setActiveDay and restoreFromSnapshot)
  // Helper to initialize structures for a day (called by setActiveDayAndStartNew and prepareStructuresForRestoredDay)
void _initializeStructuresForDay(int dayIdx) {
  _disposeAllTECs(); // Clear and dispose previous TECs first

  activeDay = programProvider.split[dayIdx];
  showHistory = List.filled(programProvider.exercises[dayIdx].length, false, growable: true);
  
  isExerciseComplete = List.filled(
    programProvider.exercises[dayIdx].length,
    false,
    growable: true,
  );
  // Initialize based on programProvider's data for the dayIdx
  // This structure must match exactly how TECs are accessed

  // For RPE Text Editing Controllers
  workoutRpeTEC = List.generate(
    programProvider.exercises[dayIdx].length, // Number of exercises for the day
    (exIdx) => List.generate(
      programProvider.sets[dayIdx][exIdx].length, // Number of set groups for this exercise
      (setIdx) => List.generate(
        programProvider.sets[dayIdx][exIdx][setIdx].numSets, // Number of actual sets (sub-sets) in this set group
        (_) => TextEditingController(), // Create a new TEC for each sub-set
      ),
      growable: true,
    ),
    growable: true,
  );

  // For Weight Text Editing Controllers
  workoutWeightTEC = List.generate(
    programProvider.exercises[dayIdx].length, // Number of exercises for the day
    (exIdx) => List.generate(
      programProvider.sets[dayIdx][exIdx].length, // Number of set groups for this exercise
      (setIdx) => List.generate(
        programProvider.sets[dayIdx][exIdx][setIdx].numSets, // Number of actual sets (sub-sets) in this set group
        (_) => TextEditingController(), // Create a new TEC for each sub-set
      ),
      growable: true,
    ),
    growable: true,
  );

  // For Reps Text Editing Controllers
  workoutRepsTEC = List.generate(
    programProvider.exercises[dayIdx].length, // Number of exercises for the day
    (exIdx) => List.generate(
      programProvider.sets[dayIdx][exIdx].length, // Number of set groups for this exercise
      (setIdx) => List.generate(
        programProvider.sets[dayIdx][exIdx][setIdx].numSets, // Number of actual sets (sub-sets) in this set group
        (_) => TextEditingController(), // Create a new TEC for each sub-set
      ),
      growable: true,
    ),
    growable: true,
  );

  // For Notes Text Editing Controllers (one per exercise)
  workoutNotesTEC = List.generate(
    programProvider.exercises[dayIdx].length,
    (_) => TextEditingController(),
    growable: true,
  );

  // For Expansion Tile Controllers (one per exercise)
  workoutExpansionControllers = List.generate(
    programProvider.exercises[dayIdx].length,
    (_) => ExpansionTileController(),
    growable: true,
  );
  expansionStates = List.generate(
    programProvider.exercises[dayIdx].length,
    (index) => (index == nextSet[0]) ? true : false,
    growable: true,
  );

  //debugPrint("Structures initialized for day index: $dayIdx with ${programProvider.exercises[dayIdx].length} exercises.");
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
    _ensureLength(expansionStates, numExercises, () => false);
    if (showHistory != null) _ensureLength(showHistory!, numExercises, () => false);
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

  // Call this when user explicitly starts a NEW workout or switches days
  Future<void> setActiveDayAndStartNew(int? index, {String? existingSessionId}) async {
    workoutStartTime = DateTime.now();
    lastRestStartTime = DateTime.now();
    if (activeDayIndex != null && activeDayIndex != index) {
      // If switching from another active day, consider saving its state if it wasn't completed
      // For now, we assume starting a new day/workout clears any previous in-progress state
    }

    if (index != null && index >= 0 && index < programProvider.split.length) {
      await clearActiveWorkoutState(); // Clear any old snapshot when starting fresh for a day

      activeDayIndex = index;
      _initializeStructuresForDay(activeDayIndex!); // Use the helper

      if (existingSessionId != null) {
        sessionID = existingSessionId; // Used during resume flow
        // Timers are handled by restoreFromSnapshot
      } else {
        sessionID = _generateNewSessionId(); // Generate new ID and start timers
        startTimers(); // Start UI timer and stopwatches
      }
      isPaused = false;
      nextSet = [0,0,0]; // Reset nextSet
      shakeFinish = false;

    } else { // Clearing active day
      timer?.cancel();
      
      _disposeAllTECs();
      activeDayIndex = null;
      activeDay = null;
      showHistory = null;
      sessionID = null;
      isPaused = false;
      nextSet = [0,0,0];
      await clearActiveWorkoutState(); // Clear snapshot when workout is explicitly ended/cleared
    }
    notifyListeners();
  }

  // Renamed from your generateWorkoutSessionId to avoid confusion with starting timers prematurely
  String _generateNewSessionId() {
    final now = DateTime.now();
    final timestamp = now.toIso8601String();
    // debugPrint("Generated new session ID: $timestamp");
    return timestamp;
  }

  // void startTimers() {
  //   debugPrint("UI Timer and Stopwatches started!");
  //   timer?.cancel(); // Ensure only one UI timer
  //   timer = Timer.periodic(const Duration(seconds: 1), (_) {
  //     if (!isPaused) {
  //       notifyListeners();
  //     }
  //   });
  //   workoutStartTime = DateTime.now();
  //   lastRestStartTime = DateTime.now();
  //   // notifyListeners(); // Not needed here, timer will do it
  // }

  // Your original togglePause remains useful
  void togglePause() {
    isPaused = !isPaused;
    notifyListeners();
    // Consider saving state on pause if app might be killed
    // saveActiveWorkoutState();
  }

  // Your incrementSet remains useful
  // void incrementSet(List<int> justDone) { ... }

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