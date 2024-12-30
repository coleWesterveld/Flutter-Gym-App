import 'package:flutter/material.dart';
//import 'data_saving.dart';
import 'database/database_helper.dart';
import 'database/profile.dart';
//import 'dart:math';
// split, sets, etc in provider
// on opening app, set split data and other data to whatever is in database
// database is initialized with values but is then changed by user
// give that split to provider
// whenever data is changed, update database in provider asynchronously
// whenever we retrieve data from provider, we now have to user futurebuilder

// A lot of the database functionality here could maybe be double checked...

/*
 This function will return Datetime of certain day of current week
 eg. monday of this week, or thursday of this week
 takes int 1-7, 1 is monday, 7 is sunday
*/
DateTime getDayOfCurrentWeek(int desiredWeekday) {
  assert(desiredWeekday >= 1 && desiredWeekday <= 7, 
      "desiredWeekday must be an integer between 1 (Monday) and 7 (Sunday)");

  DateTime now = DateTime.now(); // Current date and time
  int currentWeekday = now.weekday; // 1 (Monday) to 7 (Sunday)
  
  // Calculate the desired day's date
  DateTime targetDate = now.add(Duration(days: desiredWeekday - currentWeekday));
  return DateTime(targetDate.year, targetDate.month, targetDate.day); // Return at midnight
}

class Profile extends ChangeNotifier {
  static const List<Color> colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.yellow,
  ];

  //information of each day of the split
  List<Day> split = [];
  //excercises for each day
  List<List<Excercise>> excercises = [];
  //stores information on each set of each excercise of each day
  List<List<List<PlannedSet>>> sets = [];

  DatabaseHelper dbHelper;
  int? activeDayIndex;
  Day? activeDay;

  //defaults to monday of this week
  DateTime _origin = getDayOfCurrentWeek(1);

  // this updates listeners whenever value is changed. this should maybe be used for all variables
  // this is the only one I ve had to do this for, otherwise my schedule page wasnt updating properly
  set origin(DateTime newStartDay) {
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

  int splitLength;
  bool done;
  //bool _initialized = false;

  Profile({
    
    this.done = false,
    this.split = const <Day>[],
    this.excercises = const <List<Excercise>>[],
    this.sets = const <List<List<PlannedSet>>>[],
    this.controllers = const <ExpansionTileController>[],
    this.rpeTEC = const <List<List<TextEditingController>>>[],
    this.reps1TEC = const <List<List<TextEditingController>>>[],
    this.reps2TEC = const <List<List<TextEditingController>>>[],
    this.setsTEC = const <List<List<TextEditingController>>>[],
    required this.dbHelper,
    this.splitLength = 7,
    this.activeDayIndex,
    this.activeDay,

  }){
    _init();
  }

  Future<void> _init() async {
    // Fetch data from DB and assign to in-memory lists
    split = await dbHelper.initializeSplitList();
    excercises = await dbHelper.initializeExcerciseList();
    sets = await dbHelper.initializeSetList();


    // intiializing Text editing and expansion tile controllers
    // there may be a better way to do this...
    for (int i = 0; i < sets.length; i++){
      // each day
      controllers.add(ExpansionTileController());
      
      setsTEC.add(<List<TextEditingController>>[]);
      reps1TEC.add(<List<TextEditingController>>[]);
      reps2TEC.add(<List<TextEditingController>>[]);
      rpeTEC.add(<List<TextEditingController>>[]);
      //each excercise of each day
      for (int j = 0; j < sets[i].length; j++){
        setsTEC[i].add(<TextEditingController>[]);
        reps1TEC[i].add(<TextEditingController>[]);
        reps2TEC[i].add(<TextEditingController>[]);
        rpeTEC[i].add(<TextEditingController>[]);
        // each group of sets per excercise per day
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

  
  //I feel like there should be a better way to do all this instead of using a bunch of methods
  // but it works so thats a later problem
  void changeDone(bool val){
    done = val;
    notifyListeners();
  }

  void setActiveDay(int? index){
    activeDayIndex = (index != null && index >= 0 && index < split.length) ? index: null;
    activeDay = (index != null && index >= 0 && index < split.length) ? split[index]: null;
    notifyListeners();
  }

  // since this function is async, we will have to await it if we want a value
  void updateSplitLength() {
    //final resolvedSplit = await split; // Resolve the future
    if (split.length > 7) {
      splitLength = split.length;
    } else {
      splitLength = 7;
    }
    notifyListeners();
  }

  void splitAppend(/*{
  
    // required String newDay,
    // required List<Excercise> newExcercises,
    // required List<List<PlannedSet>> newSets,
    // required List<List<TextEditingController>> newSetsTEC,
    // required List<List<TextEditingController>> newReps1TEC,
    // required List<List<TextEditingController>> newReps2TEC,
    // required List<List<TextEditingController>> newRpeTEC,
  }*/) async {
    // this function resolves the data (waits for it to come in from future), mutates it and then reassigns it.
    // this is to ultimately add a day and update the future variables

    //final resolvedSplit = await split;
    //final resolvedExcercises = await excercises;
    //final resolvedSets = await sets;

    int id = await dbHelper.insertDay(1, "New Day", split.length);

    split.add(
      Day(
      dayOrder: split.length,
      dayTitle: "New Day", 
      programID: 1,
      dayColor: colors[(split.length + 1) % (colors.length)].value,
      dayID: id,
    ));

    excercises.add([]);

    sets.add([]);

    setsTEC.add([]);
    reps1TEC.add([]);
    reps2TEC.add([]);
    rpeTEC.add([]);
    controllers.add(ExpansionTileController());


    // split = Future.value(resolvedSplit);
    // excercises = Future.value(resolvedExcercises);
    // sets = Future.value(resolvedSets);

    updateSplitLength();
    notifyListeners();
  }

  void splitPop({
    required int index,
  }) async {
    // this resolves to future variables, deletes a given day, and then updates them
    // also updates database to reflect
    // final resolvedSplit = await split;
    // final resolvedExcercises = await excercises;
    // final resolvedSets = await sets;
    //int index = id - 1;
    int id = split[index].dayID;

    split.removeAt(index);
    excercises.removeAt(index);
    sets.removeAt(index);

    // these are not future and so can be updated directly, no need to resolve
    setsTEC.removeAt(index);
    reps1TEC.removeAt(index);
    reps2TEC.removeAt(index);
    rpeTEC.removeAt(index);

    // split = Future.value(resolvedSplit);
    // excercises = Future.value(resolvedExcercises);
    // sets = Future.value(resolvedSets);


    // this *should* cascade in database and delete all other associated excercises n stuff
    dbHelper.deleteDay(id);
    
    //dbHelper.deleteExercisesByDayId(resolvedSplit[index].dayID);
    //dbHelper.deletePlannedSet(plannedSetId);
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
    // remove the day from its old index in split
    // insert the day into its new index in the list 
    // do the same for excercises, sets and controllers
    // this should be able to be done with the remove and insert functions I made, 
    // right now idk if they work so Ill do it like this
    // TODO: use insert/delete to do this
    final moveDay = split[oldIndex];
    split.removeAt(oldIndex);
    split.insert(newIndex, moveDay);

    final moveExcercises = excercises[oldIndex];
    excercises.removeAt(oldIndex);
    excercises.insert(newIndex, moveExcercises);

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

    // TODO: evaluate performace here - this could maybe be done in another function after rebuild, and doesnt need notify listeners. performance will probably be fine either way though.
    // This is async 
    // loop through each day in split, set its day_order equal to its index
        // reorders day in database
    //dbHelper.reorderDay(programID, oldIndex, newIndex);

    //update: i did decide to move this
  }

  Future<void> updateDaysOrderInDatabase() async {
    // Loop through _split and update day_order based on the new index
    for (int i = 0; i < split.length; i++) {
      final day = split[i];
      if (day.dayOrder != i) { // If the current order differs
        split[i] = split[i].copyWith(newDayOrder: i);
        await dbHelper.updateDayOrder(day.dayID, i);
      }
    }
    //probably dont need this, and could be done after notify in other function
    // do performance check, later
    notifyListeners();
  }


  void moveExcercise({
    required int oldIndex,
    required int newIndex,
    required int dayIndex,
  }){   

    if (newIndex > oldIndex) {
      newIndex -= 1;
    } 
    // remove the day from its old index in split
    // insert the day into its new index in the list 
    // do the same for excercises, sets and controllers
    // this should be able to be done with the remove and insert functions I made, 
    // right now idk if they work so Ill do it like this
    // TODO: use insert/delete to do this
    final moveExcercises = excercises[dayIndex][oldIndex];
    excercises[dayIndex].removeAt(oldIndex);
    excercises[dayIndex].insert(newIndex, moveExcercises);

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
    
    updateExcerciseOrderInDatabase(dayIndex);
    notifyListeners();

    // TODO: evaluate performace here - this could maybe be done in another function after rebuild, and doesnt need notify listeners. performance will probably be fine either way though.
    // This is async 
    // loop through each day in split, set its day_order equal to its index
        // reorders day in database
    //dbHelper.reorderDay(programID, oldIndex, newIndex);

    //update: i did decide to move this
  }

  Future<void> updateExcerciseOrderInDatabase(int dayIndex) async {
    // Loop through _split and update day_order based on the new index
    for (int i = 0; i < excercises[dayIndex].length; i++) {
      final excercise = excercises[dayIndex][i];
      if (excercise.excerciseOrder != i) { // If the current order differs
        excercises[dayIndex][i] = excercises[dayIndex][i].copyWith(newExcerciseOrder: i);
        await dbHelper.updateExcercise(excercise.excerciseID, {'excercise_order' : i});
      }
    }
    //probably dont need this, and could be done after notify in other function
    // do performance check, later
    notifyListeners();
  }


    void moveSet({
    required int oldIndex,
    required int newIndex,
    required int dayIndex,
    required int excerciseIndex,
  }){   

    if (newIndex > oldIndex) {
      newIndex -= 1;
    } 
    // remove the day from its old index in split
    // insert the day into its new index in the list 
    // do the same for excercises, sets and controllers
    // this should be able to be done with the remove and insert functions I made, 
    // right now idk if they work so Ill do it like this
    // TODO: use insert/delete to do this
    final moveSets = sets[dayIndex][excerciseIndex][oldIndex];
    sets[dayIndex][excerciseIndex].removeAt(oldIndex);
    sets[dayIndex][excerciseIndex].insert(newIndex, moveSets);

    final moveSetsTEC = setsTEC[dayIndex][excerciseIndex][oldIndex];
    setsTEC[dayIndex][excerciseIndex].removeAt(oldIndex);
    setsTEC[dayIndex][excerciseIndex].insert(newIndex, moveSetsTEC);

    final moveRpeTEC = rpeTEC[dayIndex][excerciseIndex][oldIndex];
    rpeTEC[dayIndex][excerciseIndex].removeAt(oldIndex);
    rpeTEC[dayIndex][excerciseIndex].insert(newIndex, moveRpeTEC);

    final moveReps1TEC = reps1TEC[dayIndex][excerciseIndex][oldIndex];
    reps1TEC[dayIndex][excerciseIndex].removeAt(oldIndex);
    reps1TEC[dayIndex][excerciseIndex].insert(newIndex, moveReps1TEC);

    final moveReps2TEC = reps2TEC[dayIndex][excerciseIndex][oldIndex];
    reps2TEC[dayIndex][excerciseIndex].removeAt(oldIndex);
    reps2TEC[dayIndex][excerciseIndex].insert(newIndex, moveReps2TEC);
    
    updateExcerciseOrderInDatabase(dayIndex);
    notifyListeners();

    // TODO: evaluate performace here - this could maybe be done in another function after rebuild, and doesnt need notify listeners. performance will probably be fine either way though.
    // This is async 
    // loop through each day in split, set its day_order equal to its index
        // reorders day in database
    //dbHelper.reorderDay(programID, oldIndex, newIndex);

    //update: i did decide to move this
  }

    Future<void> updateSetOrderInDatabase(int dayIndex, int excerciseIndex) async {
    // Loop through _split and update day_order based on the new index
    for (int i = 0; i < sets[dayIndex][excerciseIndex].length; i++) {
      final plannedSet = sets[dayIndex][excerciseIndex][i];
      if (plannedSet.setOrder != i) { // If the current order differs
        sets[dayIndex][excerciseIndex][i] = sets[dayIndex][excerciseIndex][i].copyWith(newSetOrder: i);
        await dbHelper.updateExcercise(plannedSet.setID, {'set_order' : i});
      }
    }
    //probably dont need this, and could be done after notify in other function
    // do performance check, later
    notifyListeners();
  }



  /* 
  NOTE: THIS DOES NOT REASSIGN SETS OR EXCERCISES ASSOCIATED WITH THE DAY
  Maybe that will be added later but for now, this simplifies the database queries and updates
  also, I don't need it to do that at this point, so it improves performance
  */
  void splitAssign({
    //required int id,
    required Day newDay,
    required int index,
    // required List<Excercise> newExcercises,
    // required List<List<PlannedSet>> newSets,
    // required List<List<TextEditingController>> newSetsTEC,
    // required List<List<TextEditingController>> newReps1TEC,
    // required List<List<TextEditingController>> newReps2TEC,
    // required List<List<TextEditingController>> newRpeTEC,
  }) async {
    // final resolvedSplit = await split;
    // final resolvedExcercises = await excercises;
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
    required List<Excercise> excerciseList,
    required List<List<PlannedSet>> newSets,
    required List<List<TextEditingController>> newSetsTEC,
    required List<List<TextEditingController>> newReps1TEC,
    required List<List<TextEditingController>> newReps2TEC,
    required List<List<TextEditingController>> newRpeTEC,
  }) async {
    split.insert(index, day);
    excercises.insert(index, excerciseList);
    sets.insert(index, newSets);
    rpeTEC.insert(index, newRpeTEC);
    reps2TEC.insert(index, newReps2TEC);
    reps1TEC.insert(index, newReps1TEC);
    setsTEC.insert(index, newSetsTEC);

    dbHelper.insertDay(day.programID, day.dayTitle, index);

    updateSplitLength();
    notifyListeners();
  }

  //adds new excercise to end of list of excercises at index
  void excerciseAppend(
    {required int index}
    /*{
    // required Excercise newExcercise,
    // required List<PlannedSet> newSets,
    // required int index,
    // required List<TextEditingController> newSetsTEC,
    // required List<TextEditingController> newReps1TEC,
    // required List<TextEditingController> newReps2TEC,
    // required List<TextEditingController> newRpeTEC,
  }*/) async {
    // int dayID = split[index].dayID;
    // excercises[index].add(newExcercise);
    // sets[index].add(newSets);
    // setsTEC[index].add(newSetsTEC);
    // reps1TEC[index].add(newReps1TEC);
    // reps2TEC[index].add(newReps2TEC);
    // rpeTEC[index].add(newRpeTEC);
    int id = await dbHelper.insertExcercise(dayId: split[index].dayID, excerciseTitle: "New Excercise", excerciseOrder: excercises[index].length);

    excercises[index].add(
      Excercise(
        excerciseID: id,
        dayID: split[index].dayID,
        excerciseTitle: "New Excercise",
        excerciseOrder: excercises[index].length,
    ));

    //excercises.add([]);

    sets[index].add([]);

    setsTEC[index].add([]);
    reps1TEC[index].add([]);
    reps2TEC[index].add([]);
    rpeTEC[index].add([]);

    
    notifyListeners();
  }

  //removes an excercise  from certain index in certain day in list
  void excercisePop({
    required int index1,
    required int index2,
  }) async {
    dbHelper.deleteExercise(excercises[index1][index2].excerciseID);
    excercises[index1].removeAt(index2);
    sets[index1].removeAt(index2);
    setsTEC[index1].removeAt(index2);
    reps1TEC[index1].removeAt(index2);
    reps2TEC[index1].removeAt(index2);
    rpeTEC[index1].removeAt(index2);
    updateExcerciseOrderInDatabase(index1); 

    
    notifyListeners();
  }

  //assigns value for an excercise on a day
  void excerciseAssign({
    required int index1,
    required int index2,
    required Excercise data,
    //required int id,
    //required List<PlannedSet> newSets,
    // required List<TextEditingController> newSetsTEC,
    // required List<TextEditingController> newReps1TEC,
    // required List<TextEditingController> newReps2TEC,
    // required List<TextEditingController> newRpeTEC,

  }) async {
    dbHelper.updateExcercise(excercises[index1][index2].excerciseID, {'excercise_title': data.excerciseTitle});
    excercises[index1][index2] = data;
    //sets[index1][index2] = newSets;
    // setsTEC[index1][index2] =  newSetsTEC;
    // reps1TEC[index1][index2] =  newReps1TEC;
    // reps2TEC[index1][index2] =  newReps2TEC;
    // rpeTEC[index1][index2] =  newRpeTEC;

    
    notifyListeners();
  }

  //inserts excercise onto a specific day in list
  void excerciseInsert({
    required int index1,
    required int index2,
    required Excercise data,
    required List<PlannedSet> newSets,

    required List<TextEditingController> newSetsTEC,
    required List<TextEditingController> newReps1TEC,
    required List<TextEditingController> newReps2TEC,
    required List<TextEditingController> newRpeTEC,
  }) async {
    excercises[index1].insert(index2, data);
    excercises[index1].insert(index2, data);
    sets[index1].insert(index2, newSets);
    setsTEC[index1].insert(index2, newSetsTEC);
    reps1TEC[index1].insert(index2, newReps1TEC);
    reps2TEC[index1].insert(index2, newReps2TEC);
    rpeTEC[index1].insert(index2, newRpeTEC);

    dbHelper.insertExcercise(dayId: excercises[index1][index2].dayID, excerciseTitle: data.excerciseTitle, excerciseOrder: index2);

    notifyListeners();
  }

  //removes an excercise  from certain index in certain day in list
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

  //assigns value for an excercise on a day
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
    sets[index1][index2][index3] = data;

    newSetsTEC = newSetsTEC ?? TextEditingController();
    newReps2TEC = newReps2TEC ?? TextEditingController();
    newReps1TEC = newReps1TEC ?? TextEditingController();
    newRpeTEC = newRpeTEC ?? TextEditingController();

    setsTEC[index1][index2][index3] = newSetsTEC;
    reps1TEC[index1][index2][index3] = newReps1TEC;
    reps2TEC[index1][index2][index3] = newReps2TEC;
    rpeTEC[index1][index2][index3] = newRpeTEC;

    dbHelper.updatePlannedSet(data.setID, data.numSets, data.setLower, data.setUpper ?? -1);
    notifyListeners();
  }

  //inserts excercise onto a specific day in list
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

    dbHelper.insertPlannedSet(data.excerciseID, data.numSets, data.setLower, data.setUpper ?? -1, index3, data.rpe);
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
    int id = await dbHelper.insertPlannedSet(excercises[index1][index2].excerciseID, -1, -1, -1, sets[index1][index2].length, -1);
    
    sets[index1][index2].add(PlannedSet(
      excerciseID: excercises[index1][index2].excerciseID,
      setID: id,
      numSets: 1,
      setLower: -1,
      setUpper: -1,
      setOrder: sets[index1][index2].length,
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
    notifyListeners();
  }
}