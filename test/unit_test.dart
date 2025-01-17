import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// //import 'package:shared_preferences/shared_preferences.dart';
// import 'workout_selection_page.dart';
// import 'schedule_page.dart';
// import 'program_page.dart';
// import 'analytics_page.dart';
// import 'user.dart';
// import 'data_saving.dart';
import 'package:firstapp/database/database_helper.dart';
import 'package:firstapp/database/profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:developer';
import 'package:logger/logger.dart';

void main() {
  // this specific test format thanks to https://www.youtube.com/watch?v=jSaoTC1ULB8
  // arrange , act, assert
  // setup, do, test
  // test name, 
  var logger = Logger();

logger.d("Logger is working!");
  test('Testing database operations', () async{
    // Initialize FFI
sqfliteFfiInit();


 databaseFactory = databaseFactoryFfi;
    
    final dbHelper = DatabaseHelper.instance;

    List<Day> split = await dbHelper.initializeSplitList();
    List<List<Exercise>> excercises = await dbHelper.initializeExerciseList();

    for (var day in split){
          debugPrint(day.toString());

    }
    for (var excl in excercises){
      for(var ex in excl){
        log(ex.toString());
      } 
          

    }
    
    // for now I just wanted to output values to see them
    expect("", "");
  });
}