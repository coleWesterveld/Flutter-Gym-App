import 'package:flutter/material.dart';

class Profile extends ChangeNotifier {
  List<String> split;
  List<List<String>> excercises;

  Profile({
    required this.split,
    required this.excercises

  });
  //I feel like there should be a better way to do all this instead of using a bunch of methods 
  // but it works so thats a later problem


  void splitAppend({
    required String newDay,
  }) async {
    split.add(newDay);
    notifyListeners();
  }

  void splitPop({
    required int index,
  }) async {
    split.removeAt(index);
    notifyListeners();
  }

  void splitAssign({
    required int index,
    required String data,
  }) async {
    split[index] = data;
    notifyListeners();
  }

  //inserts data at index, pushes everythign after it back
  void splitInsert({
    required int index,
    required String data,
  }) async {
    split.insert(index, data);
    notifyListeners();
  }

  //adds new excercise to end of list of excercises at index
  void excerciseAppend({
    required String newExcercise,
    required int index,
  }) async {
    excercises[index].add(newExcercise);
    notifyListeners();
  }

  //adds new day to end of list
  void excerciseAppendList({
    required List<String> newDay,
  }) async {
    excercises.add(newDay);
    notifyListeners();
  }

  //removes an excercise  from certain index in certain day in list
  void excercisePop({
    required int index1,
    required int index2,
  }) async {
    excercises[index1].removeAt(index2);
    notifyListeners();
  }

  //removes a day from certain index in list
  void excercisePopList({
    required int index,
  }) async {
    excercises.removeAt(index);
    notifyListeners();
  }

  //assigns value for an excercise on a day
  void excerciseAssign({
    required int index1,
    required int index2,
    required String data,
  }) async {
    excercises[index1][index2] = data;
    notifyListeners();
  }

  //assigns value for entiere list of excercises in list
  void excerciseAssignList({
    required int index,
    required List<String> data,
  }) async {
    excercises[index] = data;
    notifyListeners();
  }

  //inserts excercise onto a specific day in list
  void excerciseInsert({
    required int index1,
    required int index2,
    required String data,
  }) async {
    excercises[index1].insert(index2, data);
    notifyListeners();
  }

  //inserts a new list of excercises into list
  void excerciseInsertList({
    required int index,
    required List<String> data,
  }) async {
    excercises.insert(index, data);
    notifyListeners();
  }
}