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

  int splitLength;
  int uuidCount;
  Profile({
    required this.uuidCount,
    required this.split,
    required this.excercises,
    required this.sets,
    this.splitLength = 7,

  });
  //I feel like there should be a better way to do all this instead of using a bunch of methods 
  // but it works so thats a later problem
  void lengthUpdate() async {
    if (split.length > 7){
      splitLength = split.length;
    }
    else{
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
  }) async {
    split.add(SplitDayData(data: "New Day", dayColor: colors[split.length + 1]));
    excercises.add(newExcercises);
    sets.add(newSets);
    lengthUpdate();
    notifyListeners();
  }

  void splitPop({
    required int index,
  }) async {
    split.removeAt(index);
    excercises.removeAt(index);
    sets.removeAt(index);
    lengthUpdate();
    notifyListeners();
  }

  void splitAssign({
    required int index,
    required SplitDayData newDay,
    required List<SplitDayData> newExcercises,
    required List<List<SplitDayData>> newSets,
  }) async {
    split[index] = newDay;
    excercises[index] = newExcercises;
    sets[index] = newSets;
    notifyListeners();
  }

  //inserts data at index, pushes everythign after it back
  void splitInsert({
    required int index,
    required SplitDayData days,
    required List<SplitDayData> excerciseList,
    required List<List<SplitDayData>> newSets,
  }) async {
    split.insert(index, days);
    excercises.insert(index, excerciseList);
    sets.insert(index, newSets);
    lengthUpdate();
    notifyListeners();
  }

  //adds new excercise to end of list of excercises at index
  void excerciseAppend({
    required SplitDayData newExcercise,
    required List<SplitDayData> newSets,
    required int index,
  }) async {
    excercises[index].add(newExcercise);
    sets[index].add(newSets);
    notifyListeners();
  }

  //removes an excercise  from certain index in certain day in list
  void excercisePop({
    required int index1,
    required int index2,
  }) async {
    excercises[index1].removeAt(index2);
    sets[index1].removeAt(index2);
    notifyListeners();
  }

  //assigns value for an excercise on a day
  void excerciseAssign({
    required int index1,
    required int index2,
    required SplitDayData data,
    required List<SplitDayData> newSets,
  }) async {
    excercises[index1][index2] = data;
    sets[index1][index2] = newSets;
    notifyListeners();
  }

  //inserts excercise onto a specific day in list
  void excerciseInsert({
    required int index1,
    required int index2,
    required SplitDayData data,
    required List<SplitDayData> newSets,
  }) async {
    excercises[index1].insert(index2, data);
    sets[index1].insert(index2, newSets);
    notifyListeners();
  }

  //removes an excercise  from certain index in certain day in list
  void setsPop({
    required int index1,
    required int index2,
    required int index3,
  }) async {
    sets[index1][index2].removeAt(index3);
    notifyListeners();
  }

  //assigns value for an excercise on a day
  void setsAssign({
    required int index1,
    required int index2,
    required int index3,
    required SplitDayData data,
  }) async {
    sets[index1][index2][index3] = data;
    notifyListeners();
  }

  //inserts excercise onto a specific day in list
  void setsInsert({
    required int index1,
    required int index2,
    required int index3,
    required SplitDayData data,
  }) async {
    sets[index1][index2].insert(index3, data);
    notifyListeners();
  }

    //adds new set to end of list of sets at [index1][index2]
  void setsAppend({
    required SplitDayData newSets,
    required int index1,
    required int index2,
  }) async {
    sets[index1][index2].add(newSets);
    notifyListeners();
  }
}