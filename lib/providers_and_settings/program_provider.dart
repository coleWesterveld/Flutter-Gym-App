import 'package:flutter/material.dart';
//import 'data_saving.dart';
import '../database/database_helper.dart';
import '../database/profile.dart';
  // import 'dart:math';
  import 'dart:async';
  import '../../other_utilities/day_of_week.dart';
  import 'package:firstapp/notifications/notification_service.dart';
  import 'package:provider/provider.dart';
  import 'package:firstapp/providers_and_settings/settings_provider.dart';

// one thing that could be done is to keep an in memory list of programs 
// so we dont have to do all this disk I/O to check and change active program to make UI more responsive
// but for now, this is ok. 

// split, sets, etc in provider
// on opening app, set split data and other data to whatever is in database
// database is initialized with values but is then changed by user
// give that split to provider
// whenever data is changed, update database in provider asynchronously
// whenever we retrieve data from provider, we now have to user futurebuilder

// A lot of the database functionality here could maybe be double checked...

// okay, im gonna try breaking this up into a few different Providers
//

class Profile extends ChangeNotifier {

  // these should move to theme or smthn
  static const List<Color> colors = [
    Colors.indigo,
    Colors.red,
    Colors.green,
    Colors.deepPurple,
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.cyan,
    Colors.teal,

    Colors.yellow,
  ];

  //information of each day of the split
  List<Day> split = [];
  //exercises for each day
  List<List<Exercise>> exercises = [];
  //stores information on each set of each exercise of each day
  List<List<List<PlannedSet>>> sets = [];
  late Program currentProgram;

  List<int> _editIndex = [-1, -1, -1];
  bool isInitialized = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  set editIndex(List<int> newVal){
    assert(newVal.length == 3, "edit index must be length 3");
    _editIndex = newVal;
    notifyListeners();
  }

  List<int> get editIndex {
    return _editIndex;
  }

  DatabaseHelper dbHelper;

  Future<int> logSet(SetRecord record, {useMetric = false}) async{
    // debugPrint("adding ${record}");
    return await dbHelper.insertSetRecord(record, useMetric: useMetric);
  }

  // unlogs a set by index - returns number of rows affected (should just be one... good check ig)
  Future<int> deleteLoggedSet({required int recordID}) async{
    // debugPrint("deleting ${recordID}");
    return await dbHelper.deleteSetRecord(recordID);
  }

  Future<bool> updateLoggedSet({required int recordID, required Map<String, dynamic> fields}) async{
    // debugPrint("updated ${recordID}, fields: ${fields}");
    return (await dbHelper.updateSetRecord(
      recordID,
      fields
    ) == 1);
  }

  //defaults to monday of this week
  // hmm the more that I think about it, this should be an attribute of a program, not of a user
  // for now its fine
  // TODO: start day attribute of program
  DateTime _origin = getDayOfCurrentWeek(1);
  // this updates listeners  and database whenever value is changed. this should maybe be used for all variables
  // this is the only one I ve had to do this for, otherwise my schedule page wasnt updating properly
  set origin(DateTime newStartDay) {
    dbHelper.updateSettingsPartial({'program_start_date': newStartDay.toIso8601String()});
    _origin = newStartDay;
    notifyListeners(); // Notify listeners of the change
  }

  DateTime get origin => _origin;

  UserSettings? settings = UserSettings();

  int splitLength;
  bool _done = false;

  Profile({
    this.split = const <Day>[],
    this.exercises = const <List<Exercise>>[],
    this.sets = const <List<List<PlannedSet>>>[],
    required this.dbHelper,
    this.splitLength = 7,
  }){
    _initializeProfileData();
  }

  Future<void> get initializationDone => _initializationCompleter.future; // Public getter for the Future

  Future<void> _initializeProfileData() async {
    try {
      currentProgram = await dbHelper.initializeProgram();

      final programID = currentProgram.programID;

      final futures = await Future.wait([
        dbHelper.initializeSplitList(programID),
        dbHelper.initializeExerciseList(programID),
        dbHelper.initializeSetList(programID),
        dbHelper.fetchUserSettings(),
      ]);

      split = futures[0] as List<Day>;
      exercises = futures[1] as List<List<Exercise>>;
      sets = futures[2] as List<List<List<PlannedSet>>>;
      settings = futures[3] as UserSettings?;

      if (settings?.programStartDate != null) {
        _origin = settings!.programStartDate!;
      }

      updateSplitLength();
      isInitialized = true;
      notifyListeners();
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
    } catch (e) {
      debugPrint("Profile initialization failed: $e");
      _initializationCompleter.completeError(e);
    }
  }



  // This will be moved into its own provider likely...
  bool get done => _done;

  set done(bool value) {
    if (_done != value) {
      _done = value;
      notifyListeners(); // Notify widgets that listen to Profile
    }
  }

  // TODO: I think many of these methods could be simpler setters and getters?
  void changeDone(bool val){
    _done = val;
    notifyListeners();
  }

  void updateSplitLength() {
    if (split.length > 7) {
      splitLength = split.length;
    } else {
      splitLength = 7;
    }
    notifyListeners();
  }

  Future<void> changeProgram(int programID) async {
    final newProgram = await dbHelper.fetchProgramById(programID);
    if (newProgram.programID != -1) {
      currentProgram = newProgram;
    } else{
      debugPrint("No program found with ID : $programID");
    }
    notifyListeners();
  }

  void updateProgram(Program program) async {
    currentProgram = program;
    dbHelper.setCurrentProgramId(currentProgram.programID);
    _initializeProfileData();
    notifyListeners();
  }

  void deleteProgram(int programID) async {
    await dbHelper.deleteProgram(programID);

    final newProgramID = await dbHelper.getCurrentProgramId();

    if (currentProgram.programID != newProgramID){
      await changeProgram(newProgramID);
      _initializeProfileData();
    }

    notifyListeners();

  }

  void splitAppend() async {

    int id = await dbHelper.insertDay(programId: currentProgram.programID, dayTitle: "New Day", dayOrder: split.length);

    split.add(
      Day(
        dayOrder: split.length,
        dayTitle: "New Day", 
        programID: currentProgram.programID,
        dayColor: colors[(split.length) % (colors.length)].value,
        dayID: id,
      )
    );

    // add sets and exercises for the day
    exercises.add([]);
    sets.add([]);
    
    updateSplitLength();
    notifyListeners();
  }

  void splitPop({
    required int index,
  }) async {
    int id = split[index].dayID;

    split.removeAt(index);
    exercises.removeAt(index);
    sets.removeAt(index);

    // this *should* cascade in database and delete all other associated exercises n stuff
    // testing shows it does work btw
    // but a test is only as good as its tester...
    dbHelper.deleteDay(id);
    
    updateDaysOrderInDatabase();

    updateSplitLength();
    notifyListeners();
  }


  void moveDay({
    required int oldIndex,
    required int newIndex,
    required int programID,
  }){   

    if (newIndex > oldIndex) {
      newIndex -= 1;
    } 

    // this should be able to be _done with the remove and insert functions I made, 
    // right now idk if they work so Ill do it like this
    // TODO: use insert/delete to do this
    final moveDay = split[oldIndex];
    split.removeAt(oldIndex);
    split.insert(newIndex, moveDay);

    final moveExercises = exercises[oldIndex];
    exercises.removeAt(oldIndex);
    exercises.insert(newIndex, moveExercises);

    final moveSets = sets[oldIndex];
    sets.removeAt(oldIndex);
    sets.insert(newIndex, moveSets);
    
    updateDaysOrderInDatabase();
    notifyListeners();
  }

  Future<void> updateDaysOrderInDatabase() async {
    final db = await dbHelper.database; 
    await db.transaction((txn) async {
      for (int i = 0; i < split.length; i++) {
        final day = split[i];
        if (day.dayOrder != i) { // Only update if needed
          split[i] = split[i].copyWith(newDayOrder: i);
          await txn.update(
            'days', 
            {'day_order': i},
            where: 'id = ?',
            whereArgs: [day.dayID],
          );
        }
      }
    });

    // Notify listeners after transaction completes
    notifyListeners();
  }


  void moveExercise({
    required int oldIndex,
    required int newIndex,
    required int dayIndex,
  }){   

    if (newIndex > oldIndex) {
      newIndex -= 1;
    } 
    // remove the day from its old index in split
    // insert the day into its new index in the list 
    // do the same for exercises, sets and controllers
    // this should be able to be _done with the remove and insert functions I made, 
    // right now idk if they work so Ill do it like this
    // TODO: use insert/delete to do this
    final moveExercises = exercises[dayIndex][oldIndex];
    exercises[dayIndex].removeAt(oldIndex);
    exercises[dayIndex].insert(newIndex, moveExercises);

    final moveSets = sets[dayIndex][oldIndex];
    sets[dayIndex].removeAt(oldIndex);
    sets[dayIndex].insert(newIndex, moveSets);
    
    updateExerciseOrderInDatabase(dayIndex);
    notifyListeners();

    // TODO: evaluate performace here - this could maybe be _done in another function after rebuild, and doesnt need notify listeners. performance will probably be fine either way though.
    // This is async 
    // loop through each day in split, set its day_order equal to its index
        // reorders day in database
    //dbHelper.reorderDay(programID, oldIndex, newIndex);

    //update: i did decide to move this
  }

  Future<void> updateExerciseOrderInDatabase(int dayIndex) async {
    final db = await dbHelper.database; // Get database instance

    await db.transaction((txn) async {
      for (int i = 0; i < exercises[dayIndex].length; i++) {
        final exercise = exercises[dayIndex][i];
        if (exercise.exerciseOrder != i) { // Only update if needed
          exercises[dayIndex][i] = exercise.copyWith(newexerciseOrder: i);
          await txn.update(
            'exercise_instances', 
            {'exercise_order': i},
            where: 'id = ?',
            whereArgs: [exercise.exerciseID],
          );
        }
      }
    });
    // Notify listeners after transaction completes
    notifyListeners();
  }


  //trying toi fix this.. getting "database is locked?"
  // need to find whats locking it...
  void moveSet({
    required int oldIndex,
    required int newIndex,
    required int dayIndex,
    required int exerciseIndex,
  }){   

    if (newIndex > oldIndex) {
      newIndex -= 1;
    } 
    // remove the day from its old index in split
    // insert the day into its new index in the list 
    // do the same for exercises, sets and controllers
    // this should be able to be _done with the remove and insert functions I made, 
    // right now idk if they work so Ill do it like this
    // TODO: use insert/delete to do this
    final moveSets = sets[dayIndex][exerciseIndex][oldIndex];
    sets[dayIndex][exerciseIndex].removeAt(oldIndex);
    sets[dayIndex][exerciseIndex].insert(newIndex, moveSets);

    updateSetOrderInDatabase(dayIndex, exerciseIndex);
    notifyListeners();
  }

  Future<void> updateSetOrderInDatabase(int dayIndex, int exerciseIndex) async {
    // Loop through _split and update day_order based on the new index
    for (int i = 0; i < sets[dayIndex][exerciseIndex].length; i++) {
      final plannedSet = sets[dayIndex][exerciseIndex][i];
      if (plannedSet.setOrder != i) { // If the current order differs
        sets[dayIndex][exerciseIndex][i] = sets[dayIndex][exerciseIndex][i].copyWith(newSetOrder: i);
        await dbHelper.updatePlannedSet(
          plannedSet.setID, 
          {'set_order' : i});
      }
    }
    //probably dont need this, and could be _done after notify in other function
    // do performance check, later
    notifyListeners();
  }

  /* 
  NOTE: THIS DOES NOT REASSIGN SETS OR exerciseS ASSOCIATED WITH THE DAY
  Maybe that will be added later but for now, this simplifies the database queries and updates
  also, I don't need it to do that at this point, so it improves performance
  */
  void splitAssign({
    //required int id,
    required Day newDay,
    required int index,
    required BuildContext context,
  }) async {

    dbHelper.updateDay(split[index].dayID, newDay.toMap());
    split[index] = newDay;

    // If time changed, enable notifications
    if (split[index].workoutTime != newDay.workoutTime){
      // Reschedule notifications if enabled
      final settings = Provider.of<SettingsModel>(context, listen: false);
      if (settings.notificationsEnabled) {
        final notiService = NotiService();
        notiService.scheduleWorkoutNotifications(
          profile: context.read<Profile>(),
          settings: context.read<SettingsModel>(),
        );
      }
    }

    notifyListeners();
  }

  //inserts data at index, pushes everythign after it back
  // i dont trust this function after updating database, it needs testing
  void splitInsert({
    required int index,
    required Day day,
    required List<Exercise> exerciseList,
    required List<List<PlannedSet>> newSets,
  }) async {
    // Create default TEC lists if not provided

    split.insert(index, day);
    exercises.insert(index, exerciseList);
    sets.insert(index, newSets);
  
    dbHelper.insertDay(programId: day.programID, dayTitle: day.dayTitle, dayOrder: index, id: day.dayID);
    dbHelper.restoreDayWithContents(
      day: day, 
      exercises: exerciseList,
      setsForExercises: newSets,
    );

    updateSplitLength();
    notifyListeners();
  }

  void exerciseAppend({required int index, required int exerciseId}) async {
    // Insert the exercise into the database and get the inserted ID
    int id = await dbHelper.insertExercise(
      dayID: split[index].dayID,
      exerciseOrder: exercises[index].length,
      exerciseID: exerciseId,
    );

    // Fetch the title of the exercise from the exercises table
    String exerciseTitle = await dbHelper.fetchExerciseTitleById(exerciseId);

    // Add the exercise to the list with the fetched title
    exercises[index].add(
      Exercise(
        id: id,
        exerciseID: exerciseId,
        dayID: split[index].dayID,
        exerciseTitle: exerciseTitle, // Use the title from the database
        exerciseOrder: exercises[index].length,
      ),
    );

    // Add empty sets and their corresponding controllers
    sets[index].add([]);

    // Notify listeners to update the UI
    notifyListeners();
  }

  //removes an exercise  from certain index in certain day in list
  void exercisePop({
    required int index1,
    required int index2,
  }) async {
    dbHelper.deleteExerciseInstance(exercises[index1][index2].id);
    exercises[index1].removeAt(index2);
    sets[index1].removeAt(index2);
 
    updateExerciseOrderInDatabase(index1); 

    
    notifyListeners();
  }

  //assigns value for an exercise on a day
  void exerciseAssign({
    required int index1,
    required int index2,
    required Exercise data,

  }) async {
    dbHelper.updateExerciseInstance(exercises[index1][index2].exerciseID, 
      {
        'exercise_order' : data.exerciseOrder,
        'exercise_id' : data.exerciseID,
        'day_id' : data.dayID
      }
    );
    String newTitle = await dbHelper.fetchExerciseTitleById(data.exerciseID);
    exercises[index1][index2] = data.copyWith(newexerciseTitle: newTitle);


    
    notifyListeners();
  }

  //inserts exercise onto a specific day in list
void exerciseInsert({
  required int index1,
  required int index2,
  required Exercise data,
  required List<PlannedSet> newSets,

}) async {
  // Insert the exercise data
  exercises[index1].insert(index2, data);
  
  // Insert the sets
  sets[index1].insert(index2, newSets);

  // Insert into database
  await dbHelper.insertExercise(
    dayID: exercises[index1][index2].dayID, 
    exerciseOrder: index2, 
    exerciseID: data.exerciseID,
    id: data.id,
  );
  await dbHelper.insertPlannedSetsBatch(
    // CAREFUL: DO NOT CONFUSE EXERCISEID WITH ID FOR EXERCISES
    // exercise objects store instances of exercises, which reference in DB to specific exercises
    // the exerciseID is the row in the table of the exercise, ie. bench press, 
    // and the id is the row where the exercise INSTANCE of that exercise is stored in the DB
    exerciseInstanceId: exercises[index1][index2].id, 
    sets: sets[index1][index2]
  );

  notifyListeners();
}

  //removes an exercise  from certain index in certain day in list
  void setsPop({
    required int index1,
    required int index2,
    required int index3,
  }) async {
    dbHelper.deletePlannedSet(sets[index1][index2][index3].setID);
    sets[index1][index2].removeAt(index3);

    updateSetOrderInDatabase(index1, index2);
    notifyListeners();
  }

  //assigns value for an exercise on a day
  void setsAssign({
    required int index1,
    required int index2,
    required int index3,
    required PlannedSet data,
  }) async {
    // Update the data in the sets list
    sets[index1][index2][index3] = data;
    // Update database
    dbHelper.updatePlannedSet(
      data.setID, 
      {
        'num_sets': data.numSets, 
        'set_lower': data.setLower, 
        'set_upper': data.setUpper ?? 0,
        'rpe' : data.rpe,
      }
    );

    notifyListeners();
  }


  //inserts exercise onto a specific day in list
  void setsInsert({
    required int index1,
    required int index2,
    required int index3,
    required PlannedSet data,
  }) async {
  

    sets[index1][index2].insert(index3, data);

    dbHelper.insertPlannedSet(data.exerciseID, data.numSets, data.setLower, data.setUpper ?? 0, index3, data.rpe, data.setID);
    notifyListeners();
  }

  //adds new set to end of list of sets at [index1][index2]
  void setsAppend({
    //required PlannedSet newSets,
    required int index1,
    required int index2,


  }) async {
    int id = await dbHelper.insertPlannedSet(exercises[index1][index2].id, 0, 0, 0, sets[index1][index2].length, 0, null);
    
    sets[index1][index2].add(PlannedSet(
      exerciseID: exercises[index1][index2].id,
      setID: id,
      numSets: 1,
      setLower: 0,
      setUpper: 0,
      setOrder: sets[index1][index2].length + 1,
      )
      );
    // if a workout is active, update the relevant text editing controllers
    // NOTE: indexed [exercise][subset]
    // If a workout is active, update workout-specific controllers
    // TODO: recreate this in active workout provider but it actually works this time
   

    notifyListeners();
  }
}
