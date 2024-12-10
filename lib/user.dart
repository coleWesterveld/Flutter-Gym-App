import 'package:flutter/material.dart';
import 'data_saving.dart';
import 'database/database_helper.dart';
import 'database/profile.dart';
// split, sets, etc in provider
// on opening app, set split data and other data to whatever is in database
// database is initialized with values but is then changed by user
// give that split to provider
// whenever data is changed, update database in provider asynchronously
// whenever we retrieve data from provider, we now have to user futurebuilder

// A lot of the database functionality here could maybe be double checked...

class Profile extends ChangeNotifier {
  static const List<Color> colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  //information of each day of the split
  List<Day> split = [];
  //excercises for each day
  List<List<Excercise>> excercises = [];
  //stores information on each set of each excercise of each day
  List<List<List<PlannedSet>>> sets = [];

  DatabaseHelper dbHelper;

  //for expansion tiles in workout page

  //this feels awful but idk a better way to do it rn so...
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

  }){
    _init();
  }

  Future<void> _init() async {
    // Fetch data from DB and assign to in-memory lists
    split = await dbHelper.initializeSplitList();
    excercises = await dbHelper.initializeExcerciseList();
    sets = await dbHelper.initializeSetList();
    
    //_initialized = true;
    notifyListeners();
  }

  
  //I feel like there should be a better way to do all this instead of using a bunch of methods
  // but it works so thats a later problem
  void changeDone(bool val){
    done = val;
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
      dayColor: colors[split.length + 1].value,
      dayID: id,
    ));

    excercises.add([]);

    sets.add([]);

    setsTEC.add([]);
    reps1TEC.add([]);
    reps2TEC.add([]);
    rpeTEC.add([]);


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
    Day moveDay = split[oldIndex];
    List<Excercise> moveExcercise = excercises[oldIndex];
    List<List<PlannedSet>> moveSet = sets[oldIndex];

    List<List<TextEditingController>> moveReps1TEC = reps1TEC[oldIndex];
    List<List<TextEditingController>> moveReps2TEC = reps2TEC[oldIndex];
    List<List<TextEditingController>> moveSetsTEC = setsTEC[oldIndex];
    List<List<TextEditingController>> moveRpeTEC = rpeTEC[oldIndex];

    // this pops all sets and excercises accordingly
    splitPop(index: oldIndex);

    splitInsert(
      index: newIndex, 
      day: moveDay, 
      excerciseList: moveExcercise, 
      newSets: moveSet, 
      newSetsTEC: moveSetsTEC, 
      newReps1TEC: moveReps1TEC, 
      newReps2TEC: moveReps2TEC, 
      newRpeTEC: moveRpeTEC
    );

    // reorders day in database
    dbHelper.reorderDay(programID, oldIndex, newIndex);
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
    dbHelper.updateDay(split[index].dayID, newDay.dayTitle);
    split[index] = newDay;


    //dbHelper.updateExercises();
    // should update other data here I think

    notifyListeners();
  }

  //inserts data at index, pushes everythign after it back
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
    // rpeTEC[index].add(newRpeTEC);//socks
    int id = await dbHelper.insertExercise(split[index].dayID, "New Excercise");

    excercises[index].add(
      Excercise(
        excerciseID: id,
        dayID: split[index].dayID,
        excerciseTitle: "New Excercise",
    ));

    excercises.add([]);

    sets.add([]);

    setsTEC.add([]);
    reps1TEC.add([]);
    reps2TEC.add([]);
    rpeTEC.add([]);

    
    notifyListeners();
  }

  //removes an excercise  from certain index in certain day in list
  void excercisePop({
    required int index1,
    required int index2,
  }) async {
    excercises[index1].removeAt(index2);
    sets[index1].removeAt(index2);
    setsTEC[index1].removeAt(index2);
    reps1TEC[index1].removeAt(index2);
    reps2TEC[index1].removeAt(index2);
    rpeTEC[index1].removeAt(index2);

    dbHelper.deleteExercise(excercises[index1][index2].excerciseID);
    notifyListeners();
  }

  //assigns value for an excercise on a day
  void excerciseAssign({
    required int index1,
    required int index2,
    required Excercise data,
    //required int id,//socks
    //required List<PlannedSet> newSets,
    // required List<TextEditingController> newSetsTEC,
    // required List<TextEditingController> newReps1TEC,
    // required List<TextEditingController> newReps2TEC,
    // required List<TextEditingController> newRpeTEC,

  }) async {
    dbHelper.updateExercise(excercises[index1][index2].excerciseID, data.excerciseTitle);
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

    dbHelper.insertExercise(excercises[index1][index2].dayID, data.excerciseTitle);

    notifyListeners();
  }

  //removes an excercise  from certain index in certain day in list
  void setsPop({
    required int index1,
    required int index2,
    required int index3,
  }) async {
    sets[index1][index2].removeAt(index3);

    setsTEC[index1][index2].removeAt(index3);

    reps1TEC[index1][index2].removeAt(index3);

    reps2TEC[index1][index2].removeAt(index3);

    rpeTEC[index1][index2].removeAt(index3);

    dbHelper.deletePlannedSet(sets[index1][index2][index3].setID);
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

    dbHelper.insertPlannedSet(data.excerciseID, data.numSets, data.setLower, data.setUpper ?? -1);
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
    int id = await dbHelper.insertPlannedSet(excercises[index1][index2].excerciseID, -1, -1, -1);
    
    sets[index1][index2].add(PlannedSet(
      excerciseID: excercises[index1][index2].excerciseID,
      setID: id,
      numSets: 1,
      setLower: -1,
      setUpper: -1,
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