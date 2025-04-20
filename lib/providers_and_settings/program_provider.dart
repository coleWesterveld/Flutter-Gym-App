import 'package:flutter/material.dart';
//import 'data_saving.dart';
import '../database/database_helper.dart';
import '../database/profile.dart';
  // import 'dart:math';
  import 'dart:async';
  import '../../other_utilities/day_of_week.dart';

//import 'dart:math';
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

  DatabaseHelper dbHelper;


  void logSet(SetRecord record){
    dbHelper.insertSetRecord(record);
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



  //for expansion tiles in workout page

  //this feels a bit inefficient but idk a better way to do it rn so...
  //this is for all the textboxes in program page
  List<ExpansionTileController> controllers;
  List<List<List<TextEditingController>>> setsTEC;
  List<List<List<TextEditingController>>> rpeTEC;
  List<List<List<TextEditingController>>> reps1TEC;
  List<List<List<TextEditingController>>> reps2TEC;

  UserSettings? settings = UserSettings();

  int splitLength;
  bool _done = false;

  Profile({
    this.split = const <Day>[],
    this.exercises = const <List<Exercise>>[],
    this.sets = const <List<List<PlannedSet>>>[],
    this.controllers = const <ExpansionTileController>[],
    this.rpeTEC = const <List<List<TextEditingController>>>[],
    this.reps1TEC = const <List<List<TextEditingController>>>[],
    this.reps2TEC = const <List<List<TextEditingController>>>[],
    this.setsTEC = const <List<List<TextEditingController>>>[],
    
    required this.dbHelper,
    this.splitLength = 7,
  }){
    _init();
  }

  Future<void> _init() async {
    // TODO: I think these need to be disposed first, memory is leaking
    controllers.clear();
    setsTEC.clear();
    reps1TEC.clear();
    reps2TEC.clear();
    rpeTEC.clear();
    currentProgram = await dbHelper.initializeProgram();
    // Fetch data from DB and assign to in-memory lists
    split = await dbHelper.initializeSplitList(currentProgram.programID);
    exercises = await dbHelper.initializeExerciseList(currentProgram.programID);
    sets = await dbHelper.initializeSetList(currentProgram.programID);

    // I am just getting settings for the _origin
    // this is remnant of legacy (2 month old, super old clearly) code 
    // that I havent fully switched over to settings provider fully yet
    settings = await dbHelper.fetchUserSettings();
    //assert(settings != null, "settings not found...");
    if (settings?.programStartDate != null) _origin = settings!.programStartDate!;
    
    // intiializing Text editing and expansion tile controllers
    // there may be a better way to do this...
    for (int i = 0; i < sets.length; i++){
      // each day
      controllers.add(ExpansionTileController());
      
      
      
      setsTEC.add(<List<TextEditingController>>[]);
      reps1TEC.add(<List<TextEditingController>>[]);
      reps2TEC.add(<List<TextEditingController>>[]);
      rpeTEC.add(<List<TextEditingController>>[]);
      //each exercise of each day
      for (int j = 0; j < sets[i].length; j++){
        setsTEC[i].add(<TextEditingController>[]);
        reps1TEC[i].add(<TextEditingController>[]);
        reps2TEC[i].add(<TextEditingController>[]);
        rpeTEC[i].add(<TextEditingController>[]);
        // each group of sets per exercise per day
        for (int k = 0; k < sets[i][j].length; k++){
          setsTEC[i][j].add(TextEditingController());
          reps1TEC[i][j].add(TextEditingController());
          reps2TEC[i][j].add(TextEditingController());
          rpeTEC[i][j].add(TextEditingController());

          setsTEC[i][j][k].text = sets[i][j][k].numSets.toString();
          reps1TEC[i][j][k].text = sets[i][j][k].setLower.toString();
          reps2TEC[i][j][k].text = sets[i][j][k].setUpper.toString();
          rpeTEC[i][j][k].text = sets[i][j][k].rpe.toString();
          
        }
      }
    }
    
    //_initialized = true;
    notifyListeners();
  }


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

  void changeProgram(int programID) async {
    final newProgram = await dbHelper.fetchProgramById(programID);
    if (newProgram.programID != -1) {
      currentProgram = newProgram;
    } else{
      ("No program found with ID : $programID");
    }

    notifyListeners();
  }

  void updateProgram(Program program) async {
    currentProgram = program;
    dbHelper.setCurrentProgramId(currentProgram.programID);
    _init();
    // split = await dbHelper.initializeSplitList(currentProgram.programID);
    // exercises = await dbHelper.initializeExerciseList(currentProgram.programID);
    // sets = await dbHelper.initializeSetList(currentProgram.programID);
    notifyListeners();

    
   
  }

  void splitAppend() async {

    int id = await dbHelper.insertDay(programId: currentProgram.programID, dayTitle: "New Day", dayOrder: split.length);

    split.add(
      Day(
        dayOrder: split.length + 1,
        dayTitle: "New Day", 
        programID: currentProgram.programID,
        dayColor: colors[(split.length + 1) % (colors.length)].value,
        dayID: id,
      )
    );

    // add sets and exercises and TECs for the day
    exercises.add([]);
    sets.add([]);

    setsTEC.add([]);
    reps1TEC.add([]);
    reps2TEC.add([]);
    rpeTEC.add([]);
    controllers.add(ExpansionTileController());

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

    setsTEC.removeAt(index);
    reps1TEC.removeAt(index);
    reps2TEC.removeAt(index);
    rpeTEC.removeAt(index);

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

    final moveexercises = exercises[oldIndex];
    exercises.removeAt(oldIndex);
    exercises.insert(newIndex, moveexercises);

    final moveSets = sets[oldIndex];
    sets.removeAt(oldIndex);
    sets.insert(newIndex, moveSets);

    final moveSetsTEC = setsTEC[oldIndex];
    setsTEC.removeAt(oldIndex);
    setsTEC.insert(newIndex, moveSetsTEC);

    final moveControllers = controllers[oldIndex];
    controllers.removeAt(oldIndex);
    controllers.insert(newIndex, moveControllers);

    final moveRpeTEC = rpeTEC[oldIndex];
    rpeTEC.removeAt(oldIndex);
    rpeTEC.insert(newIndex, moveRpeTEC);

    final moveReps1TEC = reps1TEC[oldIndex];
    reps1TEC.removeAt(oldIndex);
    reps1TEC.insert(newIndex, moveReps1TEC);

    final moveReps2TEC = reps2TEC[oldIndex];
    reps2TEC.removeAt(oldIndex);
    reps2TEC.insert(newIndex, moveReps2TEC);
    
    updateDaysOrderInDatabase();
    notifyListeners();

    // TODO: evaluate performace here - this could maybe be _done in another function after rebuild, and doesnt need notify listeners. performance will probably be fine either way though.
    // This is async 
    // loop through each day in split, set its day_order equal to its index
        // reorders day in database
    //dbHelper.reorderDay(programID, oldIndex, newIndex);

    //update: i did decide to move this
  }

Future<void> updateDaysOrderInDatabase() async {
  final db = await dbHelper.database; // Get database instance
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
    final moveexercises = exercises[dayIndex][oldIndex];
    exercises[dayIndex].removeAt(oldIndex);
    exercises[dayIndex].insert(newIndex, moveexercises);

    final moveSets = sets[dayIndex][oldIndex];
    sets[dayIndex].removeAt(oldIndex);
    sets[dayIndex].insert(newIndex, moveSets);

    final moveSetsTEC = setsTEC[dayIndex][oldIndex];
    setsTEC[dayIndex].removeAt(oldIndex);
    setsTEC[dayIndex].insert(newIndex, moveSetsTEC);

    final moveRpeTEC = rpeTEC[dayIndex][oldIndex];
    rpeTEC[dayIndex].removeAt(oldIndex);
    rpeTEC[dayIndex].insert(newIndex, moveRpeTEC);

    final moveReps1TEC = reps1TEC[dayIndex][oldIndex];
    reps1TEC[dayIndex].removeAt(oldIndex);
    reps1TEC[dayIndex].insert(newIndex, moveReps1TEC);

    final moveReps2TEC = reps2TEC[dayIndex][oldIndex];
    reps2TEC[dayIndex].removeAt(oldIndex);
    reps2TEC[dayIndex].insert(newIndex, moveReps2TEC);
    
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
    ("reordered");
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

    final moveSetsTEC = setsTEC[dayIndex][exerciseIndex][oldIndex];
    setsTEC[dayIndex][exerciseIndex].removeAt(oldIndex);
    setsTEC[dayIndex][exerciseIndex].insert(newIndex, moveSetsTEC);

    final moveRpeTEC = rpeTEC[dayIndex][exerciseIndex][oldIndex];
    rpeTEC[dayIndex][exerciseIndex].removeAt(oldIndex);
    rpeTEC[dayIndex][exerciseIndex].insert(newIndex, moveRpeTEC);

    final moveReps1TEC = reps1TEC[dayIndex][exerciseIndex][oldIndex];
    reps1TEC[dayIndex][exerciseIndex].removeAt(oldIndex);
    reps1TEC[dayIndex][exerciseIndex].insert(newIndex, moveReps1TEC);

    final moveReps2TEC = reps2TEC[dayIndex][exerciseIndex][oldIndex];
    reps2TEC[dayIndex][exerciseIndex].removeAt(oldIndex);
    reps2TEC[dayIndex][exerciseIndex].insert(newIndex, moveReps2TEC);
    
    updateSetOrderInDatabase(dayIndex, exerciseIndex);
    notifyListeners();

    // TODO: evaluate performace here - this could maybe be _done in another function after rebuild, and doesnt need notify listeners. performance will probably be fine either way though.
    // This is async 
    // loop through each day in split, set its day_order equal to its index
        // reorders day in database
    //dbHelper.reorderDay(programID, oldIndex, newIndex);

    //update: i did decide to move this
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
    // required List<exercise> newexercises,
    // required List<List<PlannedSet>> newSets,
    // required List<List<TextEditingController>> newSetsTEC,
    // required List<List<TextEditingController>> newReps1TEC,
    // required List<List<TextEditingController>> newReps2TEC,
    // required List<List<TextEditingController>> newRpeTEC,
  }) async {
    // final resolvedSplit = await split;
    // final resolvedexercises = await exercises;
    // final resolvedSets = await sets;
    //int index = id - 1;
    dbHelper.updateDay(split[index].dayID, newDay.toMap());
    split[index] = newDay;

    //dbHelper.updateExercises();
    // should update other data here I think

    notifyListeners();
  }

  //inserts data at index, pushes everythign after it back
  // i dont trust this function after updating database, it needs testing
  void splitInsert({
    required int index,
    required Day day,
    required List<Exercise> exerciseList,
    required List<List<PlannedSet>> newSets,
    List<List<TextEditingController>>? newSetsTEC,
    List<List<TextEditingController>>? newReps1TEC,
    List<List<TextEditingController>>? newReps2TEC,
    List<List<TextEditingController>>? newRpeTEC,
  }) async {
    // Create default TEC lists if not provided
    newSetsTEC ??= newSets.map((exerciseSets) => 
        exerciseSets.map((_) => TextEditingController()).toList()
    ).toList();
    
    newReps1TEC ??= newSets.map((exerciseSets) => 
        exerciseSets.map((_) => TextEditingController()).toList()
    ).toList();
    
    newReps2TEC ??= newSets.map((exerciseSets) => 
        exerciseSets.map((_) => TextEditingController()).toList()
    ).toList();
    
    newRpeTEC ??= newSets.map((exerciseSets) => 
        exerciseSets.map((_) => TextEditingController()).toList()
    ).toList();

    split.insert(index, day);
    exercises.insert(index, exerciseList);
    sets.insert(index, newSets);
    rpeTEC.insert(index, newRpeTEC);
    reps2TEC.insert(index, newReps2TEC);
    reps1TEC.insert(index, newReps1TEC);
    setsTEC.insert(index, newSetsTEC);

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
    setsTEC[index].add([]);
    reps1TEC[index].add([]);
    reps2TEC[index].add([]);
    rpeTEC[index].add([]);

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
    setsTEC[index1].removeAt(index2);
    reps1TEC[index1].removeAt(index2);
    reps2TEC[index1].removeAt(index2);
    rpeTEC[index1].removeAt(index2);
    updateExerciseOrderInDatabase(index1); 

    
    notifyListeners();
  }

  //assigns value for an exercise on a day
  void exerciseAssign({
    required int index1,
    required int index2,
    required Exercise data,
/*
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_order INTEGER NOT NULL,
        day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE,
        FOREIGN KEY (day_id) REFERENCES days (id) ON DELETE CASCADE
*/

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
  List<TextEditingController>? newSetsTEC,
  List<TextEditingController>? newReps1TEC,
  List<TextEditingController>? newReps2TEC,
  List<TextEditingController>? newRpeTEC,
}) async {
  // Insert the exercise data
  exercises[index1].insert(index2, data);
  
  // Insert the sets
  sets[index1].insert(index2, newSets);

  // Handle TextEditingControllers - create new ones if null
  setsTEC[index1].insert(index2, 
    newSetsTEC ?? List.generate(newSets.length, (_) => TextEditingController())
  );
  
  reps1TEC[index1].insert(index2, 
    newReps1TEC ?? List.generate(newSets.length, (_) => TextEditingController())
  );
  
  reps2TEC[index1].insert(index2, 
    newReps2TEC ?? List.generate(newSets.length, (_) => TextEditingController())
  );
  
  rpeTEC[index1].insert(index2, 
    newRpeTEC ?? List.generate(newSets.length, (_) => TextEditingController())
  );

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
    setsTEC[index1][index2].removeAt(index3);
    reps1TEC[index1][index2].removeAt(index3);
    reps2TEC[index1][index2].removeAt(index3);
    rpeTEC[index1][index2].removeAt(index3);

    updateSetOrderInDatabase(index1, index2);
    notifyListeners();
  }

  //assigns value for an exercise on a day
  void setsAssign({
    required int index1,
    required int index2,
    required int index3,
    required PlannedSet data,

    TextEditingController? newSetsTEC,
    TextEditingController? newRpeTEC,
    TextEditingController? newReps2TEC,
    TextEditingController? newReps1TEC,
  }) async {
    // Update the data in the sets list
    sets[index1][index2][index3] = data;

    // Preserve existing controllers if new ones are not provided
    setsTEC[index1][index2][index3] = newSetsTEC ?? setsTEC[index1][index2][index3];
    reps1TEC[index1][index2][index3] = newReps1TEC ?? reps1TEC[index1][index2][index3];
    reps2TEC[index1][index2][index3] = newReps2TEC ?? reps2TEC[index1][index2][index3];
    rpeTEC[index1][index2][index3] = newRpeTEC ?? rpeTEC[index1][index2][index3];

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

    TextEditingController? newSetsTEC,
    TextEditingController? newRpeTEC,
    TextEditingController? newReps2TEC,
    TextEditingController? newReps1TEC,
  }) async {
    newSetsTEC = newSetsTEC ?? TextEditingController();
    newReps2TEC = newReps2TEC ?? TextEditingController();
    newReps1TEC = newReps1TEC ?? TextEditingController();
    newRpeTEC = newRpeTEC ?? TextEditingController();

    sets[index1][index2].insert(index3, data);
    setsTEC[index1][index2].insert(index3, newSetsTEC);
    reps1TEC[index1][index2].insert(index3, newReps1TEC);
    reps2TEC[index1][index2].insert(index3, newReps2TEC);
    rpeTEC[index1][index2].insert(index3, newRpeTEC);

    dbHelper.insertPlannedSet(data.exerciseID, data.numSets, data.setLower, data.setUpper ?? 0, index3, data.rpe, data.setID);
    notifyListeners();
  }

  //adds new set to end of list of sets at [index1][index2]
  void setsAppend({
    //required PlannedSet newSets,
    required int index1,
    required int index2,

    // TextEditingController? newSetsTEC,
    // TextEditingController? newRpeTEC,
    // TextEditingController? newReps2TEC,
    // TextEditingController? newReps1TEC,

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

    // newSetsTEC = newSetsTEC ?? TextEditingController();
    // newReps2TEC = newReps2TEC ?? TextEditingController();
    // newReps1TEC = newReps1TEC ?? TextEditingController();
    // newRpeTEC = newRpeTEC ?? TextEditingController();

    
    setsTEC[index1][index2].add(TextEditingController());
    reps1TEC[index1][index2].add(TextEditingController());
    reps2TEC[index1][index2].add(TextEditingController());
    rpeTEC[index1][index2].add(TextEditingController());

    // if a workout is active, update the relevant text editing controllers
    // NOTE: indexed [exercise][subset]
    // If a workout is active, update workout-specific controllers
    // TODO: recreate this in active workout provider but it actually works this time
    // if (activeDayIndex != null) {
    //   // The new set index is the current length before adding
    //   final newSetIndex = workoutRepsTEC[index2].length;
      
    //   // Initialize lists if they don't exist
    //   workoutRepsTEC[index2].add([]);
    //   workoutRpeTEC[index2].add([]);
    //   workoutWeightTEC[index2].add([]);
      
    //   // Add controllers for each subset (using numSets from the new PlannedSet)
    //   for (int i = 0; i < sets[index1][index2].last.numSets; i++) {
    //     workoutRepsTEC[index2][newSetIndex].add(TextEditingController());
    //     workoutRpeTEC[index2][newSetIndex].add(TextEditingController());
    //     workoutWeightTEC[index2][newSetIndex].add(TextEditingController());
    //   }
    // }

    notifyListeners();
  }
}