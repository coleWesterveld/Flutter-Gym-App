import 'package:flutter/material.dart';
import 'data_saving.dart';

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
  var split = <SplitDayData>[];
  //excercises for each day
  var excercises = <List<SplitDayData>>[];
  //stores information on each set of each excercise of each day
  var sets = <List<List<SplitDayData>>>[];



  //for expansion tiles in workout page

  //this feels awful but idk a better way to do it rn so...
  //this is for all the textboxes in program page
  List<ExpansionTileController> controllers;
  List<List<List<TextEditingController>>> setsTEC;
  List<List<List<TextEditingController>>> rpeTEC;
  List<List<List<TextEditingController>>> reps1TEC;
  List<List<List<TextEditingController>>> reps2TEC;

  int splitLength;
  int uuidCount;
  bool done;

  Profile({
    this.done = false,
    required this.uuidCount,
    required this.split,
    required this.excercises,
    required this.sets,
    required this.controllers,
    required this.rpeTEC,
    required this.reps1TEC,
    required this.reps2TEC,
    required this.setsTEC,
    this.splitLength = 7,
     
  });
  //I feel like there should be a better way to do all this instead of using a bunch of methods
  // but it works so thats a later problem
  void changeDone(bool val){
    done = val;
    notifyListeners();
  }
  void lengthUpdate() async {
    if (split.length > 7) {
      splitLength = split.length;
    } else {
      splitLength = 7;
    }
    notifyListeners();
  }

  void uuidInc() async {
    uuidCount += 1;
    notifyListeners();
  }

  void splitAppend({
    required String newDay,
    required List<SplitDayData> newExcercises,
    required List<List<SplitDayData>> newSets,


    required List<List<TextEditingController>> newSetsTEC,


    required List<List<TextEditingController>> newReps1TEC,


    required List<List<TextEditingController>> newReps2TEC,


    required List<List<TextEditingController>> newRpeTEC,

  }) async {
    split
        .add(SplitDayData(data: "New Day", dayColor: colors[split.length + 1]));
    excercises.add(newExcercises);
    sets.add(newSets);

    setsTEC.add(newSetsTEC);
    reps1TEC.add(newReps1TEC);
    reps2TEC.add(newReps2TEC);
    rpeTEC.add(newRpeTEC);

    lengthUpdate();
    notifyListeners();
  }

  void splitPop({
    required int index,
  }) async {
    split.removeAt(index);
    excercises.removeAt(index);
    sets.removeAt(index);

    setsTEC.removeAt(index);
    reps1TEC.removeAt(index);
    reps2TEC.removeAt(index);
    rpeTEC.removeAt(index);

    lengthUpdate();
    notifyListeners();
  }

  void splitAssign({
    required int index,
    required SplitDayData newDay,
    required List<SplitDayData> newExcercises,
    required List<List<SplitDayData>> newSets,

   
    required List<List<TextEditingController>> newSetsTEC,

    
    required List<List<TextEditingController>> newReps1TEC,


    required List<List<TextEditingController>> newReps2TEC,

    
    required List<List<TextEditingController>> newRpeTEC,
  }) async {
    split[index] = newDay;
    excercises[index] = newExcercises;
    sets[index] = newSets;


    rpeTEC[index] = newRpeTEC;


    reps2TEC[index] = newReps2TEC;


    reps1TEC[index] = newReps1TEC;

    setsTEC[index] = newSetsTEC;
    notifyListeners();
  }

  //inserts data at index, pushes everythign after it back
  void splitInsert({
    required int index,
    required SplitDayData days,
    required List<SplitDayData> excerciseList,
    required List<List<SplitDayData>> newSets,


    required List<List<TextEditingController>> newSetsTEC,

    required List<List<TextEditingController>> newReps1TEC,

    required List<List<TextEditingController>> newReps2TEC,


    required List<List<TextEditingController>> newRpeTEC,
  }) async {
    split.insert(index, days);
    excercises.insert(index, excerciseList);
    sets.insert(index, newSets);

    rpeTEC.insert(index, newRpeTEC);

    reps2TEC.insert(index, newReps2TEC);

    reps1TEC.insert(index, newReps1TEC);

    setsTEC.insert(index, newSetsTEC);

    lengthUpdate();
    notifyListeners();
  }

  //adds new excercise to end of list of excercises at index
  void excerciseAppend({
    required SplitDayData newExcercise,
    required List<SplitDayData> newSets,
    required int index,
    required List<TextEditingController> newSetsTEC,
    required List<TextEditingController> newReps1TEC,
    required List<TextEditingController> newReps2TEC,
    required List<TextEditingController> newRpeTEC,
  }) async {
    excercises[index].add(newExcercise);
    sets[index].add(newSets);
    setsTEC[index].add(newSetsTEC);
    reps1TEC[index].add(newReps1TEC);
    reps2TEC[index].add(newReps2TEC);
    rpeTEC[index].add(newRpeTEC);
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
    notifyListeners();
  }

  //assigns value for an excercise on a day
  void excerciseAssign({
    required int index1,
    required int index2,
    required SplitDayData data,
    required List<SplitDayData> newSets,
    required List<TextEditingController> newSetsTEC,
    required List<TextEditingController> newReps1TEC,
    required List<TextEditingController> newReps2TEC,
    required List<TextEditingController> newRpeTEC,

  }) async {
    excercises[index1][index2] = data;
    sets[index1][index2] = newSets;
      //socks
  setsTEC[index1][index2] =  newSetsTEC;

  reps1TEC[index1][index2] =  newReps1TEC;

  reps2TEC[index1][index2] =  newReps2TEC;

  rpeTEC[index1][index2] =  newRpeTEC;
  notifyListeners();
  }

  //inserts excercise onto a specific day in list
  void excerciseInsert({
    required int index1,
    required int index2,
    required SplitDayData data,
    required List<SplitDayData> newSets,

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
    notifyListeners();
  }

  //assigns value for an excercise on a day
  void setsAssign({
    required int index1,
    required int index2,
    required int index3,
    required SplitDayData data,

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
    notifyListeners();
  }

  //inserts excercise onto a specific day in list
  void setsInsert({
    required int index1,
    required int index2,
    required int index3,
    required SplitDayData data,

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
    notifyListeners();
  }

  //adds new set to end of list of sets at [index1][index2]
  void setsAppend({
    required SplitDayData newSets,
    required int index1,
    required int index2,
    TextEditingController? newSetsTEC,

    TextEditingController? newRpeTEC,

    TextEditingController? newReps2TEC,

    TextEditingController? newReps1TEC,

  }) async {
    newSetsTEC = newSetsTEC ?? TextEditingController();
    newReps2TEC = newReps2TEC ?? TextEditingController();
    newReps1TEC = newReps1TEC ?? TextEditingController();
    newRpeTEC = newRpeTEC ?? TextEditingController();

    sets[index1][index2].add(newSets);
    setsTEC[index1][index2].add(newSetsTEC);

    reps1TEC[index1][index2].add(newReps1TEC);

    reps2TEC[index1][index2].add(newReps2TEC);

    rpeTEC[index1][index2].add(newRpeTEC);
    notifyListeners();
  }
}