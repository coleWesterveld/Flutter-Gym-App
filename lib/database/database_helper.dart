import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firstapp/data_saving.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/user.dart';
import 'profile.dart';
import 'dart:async';
import 'dart:io';
//import 'package:logger/logger.dart/';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_app/models/note.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
//TODO; Day order not saving properly 
// when reordering or inserting or something make sure to update all day orders
// also daycolour not saving properly, set initialzier not working properly
//import 'profile.dart';

//TODO: add order to days, as theyre not implicity stored that way 
// it is in the table but I need to include functionality
// need to use 'ORDER BY' SQL command when retrieving days so I get them in the right order
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('programs.db');
    return _database!;
  }

  //create a setup database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint('path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      }, 
    );
  }

  // create initial tables on startup
  Future _createDB(Database db, int version) async {
    await db.execute(
    '''
      CREATE TABLE programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_title TEXT NOT NULL
      );
    '''
    );

    await db.execute(
    '''
      CREATE TABLE days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_title TEXT NOT NULL,
        day_order INTEGER NOT NULL,
        program_id INTEGER NOT NULL,
        day_color INTEGER NOT NULL,
        FOREIGN KEY (program_id) REFERENCES programs (id) ON DELETE CASCADE
      );
    '''
    );

    await db.execute(
    '''
      CREATE TABLE excercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        excercise_title TEXT NOT NULL,
        persistent_note TEXT NOT NULL,
        excercise_order INTEGER NOT NULL,
        day_id INTEGER NOT NULL,
        FOREIGN KEY (day_id) REFERENCES days (id) ON DELETE CASCADE
      );
    '''
    );

    await db.execute(
    '''
      CREATE TABLE plannedSets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        num_sets INTEGER NOT NULL,
        set_lower INTEGER NOT NULL,
        set_upper INTEGER NOT NULL,
        excercise_id INTEGER NOT NULL,
        set_order INTEGER NOT NULL,
        rpe INTEGER NOT NULL,
        FOREIGN KEY (excercise_id) REFERENCES excercises (id) ON DELETE CASCADE
      );
    '''
    );

    // might want to remove on delete cascade
    await db.execute(
    '''
      CREATE TABLE setRecord (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        numSets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight INTEGER NOT NULL,
        rpe INTEGER NOT NULL,
        history_note TEXT NOT NULL,
        excercise_id INTEGER NOT NULL,
        FOREIGN KEY (excercise_id) REFERENCES excercises (id) ON DELETE CASCADE
      )
    '''
    );

    // Insert initial data
    await _insertInitialData(db);

  }

  // Add initial data to program in startup
  Future<void> _insertInitialData(Database db) async {
    // Insert initial program
    await db.insert('programs', {'program_title': 'Program1'});

    // the following manually creates an initial program, so the user can see 
    // an example of how managing a program might be structured on opening the app
    // for the first time
    // insert initial days for program
    await db.insert('days', {'program_id': 1, 'day_title': 'Push', 'day_order': 1, 'day_color': Profile.colors[0].value});
    await db.insert('days', {'program_id': 1, 'day_title': 'Pull', 'day_order' : 2, 'day_color': Profile.colors[1].value});
    await db.insert('days', {'program_id': 1, 'day_title': 'Legs', 'day_order' : 3, 'day_color': Profile.colors[2].value});

    //insert initial excercises for program
    //Push
    await db.insert('excercises', {'day_id': 1, 'excercise_title': 'Bench Press', 'persistent_note': '', 'excercise_order': 1});
    await db.insert('excercises', {'day_id': 1, 'excercise_title': 'Tricep Pushdown', 'persistent_note': '', 'excercise_order': 2});
    await db.insert('excercises', {'day_id': 1, 'excercise_title': 'Lateral Raise', 'persistent_note': '', 'excercise_order': 3});
    await db.insert('excercises', {'day_id': 1, 'excercise_title': 'Shoulder Press', 'persistent_note': '', 'excercise_order': 4});
    await db.insert('excercises', {'day_id': 1, 'excercise_title': 'Cable Chest Fly', 'persistent_note': '', 'excercise_order': 5});

    //pull  
    await db.insert('excercises', {'day_id': 2, 'excercise_title': 'Weighted Pull-ups', 'persistent_note': '', 'excercise_order': 1});
    await db.insert('excercises', {'day_id': 2, 'excercise_title': 'Cable Rows', 'persistent_note': '', 'excercise_order': 2});
    await db.insert('excercises', {'day_id': 2, 'excercise_title': 'Reverse Dumbbell Flies', 'persistent_note': '', 'excercise_order': 3});
    await db.insert('excercises', {'day_id': 2, 'excercise_title': 'Hammer Curls', 'persistent_note': '', 'excercise_order': 4});
    await db.insert('excercises', {'day_id': 2, 'excercise_title': 'Barbell Rows', 'persistent_note': '', 'excercise_order': 5});

    //legs
    await db.insert('excercises', {'day_id': 3, 'excercise_title': 'Barbell Squats', 'persistent_note': '', 'excercise_order': 1});
    await db.insert('excercises', {'day_id': 3, 'excercise_title': 'Romanian Deadlift', 'persistent_note': '', 'excercise_order': 2});
    await db.insert('excercises', {'day_id': 3, 'excercise_title': 'Calf Raises', 'persistent_note': '', 'excercise_order': 3});
    await db.insert('excercises', {'day_id': 3, 'excercise_title': 'Seated Leg Curl', 'persistent_note': '', 'excercise_order': 4});
    await db.insert('excercises', {'day_id': 3, 'excercise_title': 'Leg Extension', 'persistent_note': '', 'excercise_order': 5});

    // sets for each excercise
    // each will just start off with 3 sets, 5-8 reps
    for (int i = 1; i <= 15; i++){
      await db.insert('plannedSets', {
      'excercise_id': i, 
      'num_sets': 3,
      'set_lower': 5,
      'set_upper': 8,
      'rpe' : 8,
      'set_order': i % 5,
    });
    }
  }

  Future<List<Day>> initializeSplitList() async {
    
    // TODO: allow more than one program
    // irght now, we are just allowing 1 program, but in the future, 
    // I want to expand to allow user to have multiple programs saved
    // Fetch days from the database
    final List<Map<String, dynamic>> daysData = await fetchDays(1);
    // Map the database rows to SplitDayData objects
    final List<Day> splitList = daysData.map((day) {
      // Example: Set `dayColor` dynamically based on the data (default to a color if none specified)

      return Day(
        dayOrder: day['day_order'],
        programID: 1,
        dayColor: day['day_color'],
        dayTitle: day['day_title'], 
        dayID: day['id'],// Assuming 'day_title' is the column name in the database
        //dayColor: Profile.colors[day['day_id'] - 1],
      );
    }).toList();

    return splitList;
  }

  Future<List<List<Excercise>>> initializeExcerciseList() async {
    List<List<Excercise>> excerciseList = [];
    // TODO: allow more than one program
    // irght now, we are just allowing 1 program, but in the future, 
    // I want to expand to allow user to have multiple programs saved
    // Fetch days from the database
    List<Map<String, dynamic>> days = await fetchDays(1);

    for (var day in days){
      List<Map<String, dynamic>> excerciseData = await fetchExercises(day['id']);

      List<Excercise> excerciseDataList = excerciseData.map((excercise) {
        // Example: Set `dayColor` dynamically based on the data (default to a color if none specified)

        return Excercise(
          excerciseID: excercise['id'],
          dayID: excercise['day_id'],
          excerciseTitle: excercise['excercise_title'],
          persistentNote: excercise['persistent_note'],
          excerciseOrder: excercise['excercise_order'],
        );
      }).toList();

      excerciseList.add(excerciseDataList);
    }
    return Future.value(excerciseList);
  }

  Future<List<List<List<PlannedSet>>>> initializeSetList() async {
    List<List<List<PlannedSet>>> setList = [];
    // TODO: allow more than one program
    // irght now, we are just allowing 1 program, but in the future, 
    // I want to expand to allow user to have multiple programs saved
    // Fetch days from the database
    List<Map<String, dynamic>> days = await fetchDays(1);

    for (int i = 0; i < days.length; i++){//(var day in days){
      setList.add([]);
      List<Map<String, dynamic>> excercises = await fetchExercises(days[i]['id']);
      for (int j = 0; j < excercises.length; j++){//(var excercise in excercises){
        List<Map<String, dynamic>> setData = await fetchPlannedSets(excercises[j]['id']);

        List<PlannedSet> setDataList = setData.map((aSet) {

          return PlannedSet(

            excerciseID: aSet['excercise_id'],
            numSets: aSet['num_sets'],
            setLower: aSet['set_lower'],
            setUpper: aSet['set_upper'],
            setID: aSet['id'],
            setOrder: aSet['set_order'],
            rpe: aSet['rpe'],
            //excerciseTitle: excercise['excercise_title'],
            // persistentNote: excercise['persistent_note'],
          );
        }).toList();

        setList[i].add(setDataList);
      }
    }
    return Future.value(setList);
  }
  

  // CRUD OPERATIONS FOR TABLES
  // create
  // read
  // update
  // delete

  ////////////////////////////////////////////////////////////
  // PROGRAM TABLE CRUD

  Future<int> insertProgram(String programTitle) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('programs', {'program_title': programTitle});
  }

  Future<List<Map<String, dynamic>>> fetchPrograms() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('programs');
  }

  Future<int> updateProgram(int programId, String newTitle) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'programs',
      {'program_title': newTitle},
      where: 'id = ?',
      whereArgs: [programId],
    );
  }

  Future<int> deleteProgram(int programId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'programs',
      where: 'id = ?',
      whereArgs: [programId],
    );
  }

  ////////////////////////////////////////////////////////////
  // DAY TABLE CRUD

  Future<int> insertDay(int programId, String dayTitle, int dayOrder) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('days', {
      'program_id': programId,
      'day_title': dayTitle,
      'day_order': dayOrder,
      // CAREFUL HERE TODO: user could have a ton of days, more than colours, then crash.
      // fixed with mod (i think), it resets back 
      'day_color': Profile.colors[dayOrder % (Profile.colors.length - 1)].value
    });
  }

  Future<int> updateDayOrder(int dayId, int newOrder) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'days',
      {'day_order': newOrder},
      where: 'id = ?',
      whereArgs: [dayId],
    );
  }

  //fetches days for given program ID, ordered by day_order
  Future<List<Map<String, dynamic>>> fetchDays(int programId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'days',
      where: 'program_id = ?',
      whereArgs: [programId],
      orderBy: 'day_order ASC',
    );
  }

  //takes update values and will update them with the given value
  Future<int> updateDay(int dayId, Map<String, dynamic> updatedValues) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'days',
      updatedValues,
      where: 'id = ?',
      whereArgs: [dayId],
    );
  } 
  // Future<int> updateDay(int dayId, String newTitle) async {
  //   final db = await DatabaseHelper.instance.database;
  //   return await db.update(
  //     'days',
  //     {'day_title': newTitle},
  //     where: 'id = ?',
  //     whereArgs: [dayId],
  //   );
  // }

  Future<int> deleteDay(int dayId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'days',
      where: 'id = ?',
      whereArgs: [dayId],
    );
  }

  ////////////////////////////////////////////////////////////
  // EXCERCISE TABLE CRUD

  Future<int> insertExcercise({required int dayId, required String excerciseTitle, String persistentNote = '', required int excerciseOrder}) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('excercises', {
      'day_id': dayId,
      'excercise_title': excerciseTitle,
      'persistent_note': persistentNote,
      'excercise_order': excerciseOrder,
    });
  }

  Future<List<Map<String, dynamic>>> fetchExercises(int dayId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'excercises',
      where: 'day_id = ?',
      whereArgs: [dayId],
      orderBy: 'excercise_order ASC',
    );
  }

  Future<int> updateExcercise(int excerciseID, Map<String, dynamic> updatedValues) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'excercises',
      updatedValues,
      where: 'id = ?',
      whereArgs: [excerciseID],
    );
  } 

  Future<int> deleteExercise(int exerciseId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'excercises',
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
  }

  ////////////////////////////////////////////////////////////
  // PLANNED SET TABLE CRUD

  Future<int> insertPlannedSet(int exerciseId, int numSets, int setLower, int setUpper, int setOrder, int? rpe) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('plannedSets', {
      'excercise_id': exerciseId,
      'num_sets': numSets,
      'set_lower': setLower,
      'set_upper': setUpper,
      'set_order': setOrder,
      'rpe': rpe ?? -1,
    });
  }

  Future<List<Map<String, dynamic>>> fetchPlannedSets(int exerciseId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'plannedSets',
      where: 'excercise_id = ?',
      whereArgs: [exerciseId],
    );
  }

  Future<int> updatePlannedSet(int plannedSetId, int numSets, int setLower, int setUpper) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'plannedSets',
      {
        'num_sets': numSets,
        'set_lower': setLower,
        'set_upper': setUpper,
      },
      where: 'id = ?',
      whereArgs: [plannedSetId],
    );
  }

  Future<int> deletePlannedSet(int plannedSetId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'plannedSets',
      where: 'id = ?',
      whereArgs: [plannedSetId],
    );
  }

  ////////////////////////////////////////////////////////////
  // SET RECORD (history) TABLE CRUD

  Future<int> insertSetRecord(
    int exerciseId, String date, int numSets, int reps, int weight, int rpe, String historyNote) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('setRecord', {
      'excercise_id': exerciseId,
      'date': date,
      'numSets': numSets,
      'reps': reps,
      'weight': weight,
      'rpe': rpe,
      'history_note': historyNote,
    });
  }

  Future<List<Map<String, dynamic>>> fetchSetRecords(int exerciseId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'setRecord',
      where: 'excercise_id = ?',
      whereArgs: [exerciseId],
    );
  }

  Future<int> updateSetRecord(
    int setRecordId, String date, int numSets, int reps, int weight, int rpe, String historyNote) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'setRecord',
      {
        'date': date,
        'numSets': numSets,
        'reps': reps,
        'weight': weight,
        'rpe': rpe,
        'history_note': historyNote,
      },
      where: 'id = ?',
      whereArgs: [setRecordId],
    );
  }

  Future<int> deleteSetRecord(int setRecordId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'setRecord',
      where: 'id = ?',
      whereArgs: [setRecordId],
    );
  }

  // dont need this type of stuff if i just use ondelete cascade in tab;es
  // Future<int> deleteExercisesByDayId(int dayId) async {
  //   final db = await DatabaseHelper.instance.database; // Access the database instance
  //   return await db.delete(
  //     'exercises', // Replace with the name of your exercises table
  //     where: 'dayId = ?', // Replace 'dayId' with the actual column name in your table
  //     whereArgs: [dayId], // Bind the dayId to avoid SQL injection
  //   );
  // }



  // close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}