import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/user.dart';
import 'profile.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
//TODO: set data not saving currently for some reason
// database helper for interfacing with SQLite database
// setup tables, CRUD operations, initialization

// Problems to fix from migration: 


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // get path
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('programs.db');
    return _database!;
  }

  // setup database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint('path: $path');

    // open database at path, create tables if first time opening
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
  // this runs once, on first opening app after download
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


    // this title doesnt really need to be here, since we can get it from the id to excercises table
    // I will leave it here for now for debugging
    await db.execute(
    '''
      CREATE TABLE exercise_instances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_title TEXT NOT NULL,
        exercise_order INTEGER NOT NULL,
        day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE,
        FOREIGN KEY (day_id) REFERENCES days (id) ON DELETE CASCADE
      );
    '''
    );

    await db.execute(
    '''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_title TEXT NOT NULL,
        persistent_note TEXT NOT NULL,
        muscles_worked TEXT NOT NULL
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
        exercise_instance_id INTEGER NOT NULL,
        set_order INTEGER NOT NULL,
        rpe INTEGER NOT NULL,
        FOREIGN KEY (exercise_instance_id) REFERENCES exercise_instances (id) ON DELETE CASCADE
      );
    '''
    );

    // might want to remove on delete cascade, or make another way to save data even if typo, or used in different workouts
    // basically, this may become a many-to-many table and we may have to have a large table of all exercises saved 
    // but for now this works
    await db.execute(
    '''
      CREATE TABLE set_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        numSets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight INTEGER NOT NULL,
        rpe INTEGER NOT NULL,
        history_note TEXT NOT NULL,
        exercise_id INTEGER NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    '''
    );

    // load all excercises from text file into database
    await _loadExercisesFromText(db);

    // Insert initial data - simple push pull legs split on run after download, easily editable by user
    await _insertInitialData(db);


  }

  Future<void> _loadExercisesFromText(Database db) async {
  final data = await rootBundle.loadString('assets/exercises.txt');
  final lines = data.split('\n');

  await db.transaction((txn) async {
    for (var line in lines) {
      if (line.trim().isNotEmpty) {
        final parts = line.split(',');
        if (parts.length >= 2) {
          final name = parts[0].trim();
          final category = parts[1].trim();
          //debugPrint('Inserting exercise: $name');
          await txn.insert('exercises', {
            'exercise_title': name,
            'muscles_worked': category,
            'persistent_note': '',
          });
        }
      }
    }
    debugPrint("Done Initial Insert");
  });
}


  // Add initial data to program in startup
  Future<void> _insertInitialData(Database db) async {
    // Insert initial program, for now we just have one program
    await db.insert('programs', {'program_title': 'Program1'});
    //TODO: fix deprecated code
    // Insert initial days for program
    await db.insert('days', {'program_id': 1, 'day_title': 'Push', 'day_order': 1, 'day_color': Profile.colors[0].value});
    await db.insert('days', {'program_id': 1, 'day_title': 'Pull', 'day_order' : 2, 'day_color': Profile.colors[1].value});
    await db.insert('days', {'program_id': 1, 'day_title': 'Legs', 'day_order' : 3, 'day_color': Profile.colors[2].value});

    // Insert initial exercises for program
    // Push
    await db.insert('exercise_instances', {'day_id': 1, 'exercise_title': 'Bench Press', 'exercise_order': 1, 'exercise_id' : 70});
    await db.insert('exercise_instances', {'day_id': 1, 'exercise_title': 'Tricep Pushdown', 'exercise_order': 2, 'exercise_id' : 852});
    await db.insert('exercise_instances', {'day_id': 1, 'exercise_title': 'Lateral Raise', 'exercise_order': 3, 'exercise_id' : 690});
    await db.insert('exercise_instances', {'day_id': 1, 'exercise_title': 'Shoulder Press', 'exercise_order': 4, 'exercise_id' : 852});
    await db.insert('exercise_instances', {'day_id': 1, 'exercise_title': 'Cable Chest Fly', 'exercise_order': 5, 'exercise_id' : 852}
    );

    // // Pull  
    await db.insert('exercise_instances', {'day_id': 2, 'exercise_title': 'Weighted Pull-ups', 'exercise_order': 1, 'exercise_id' : 852});
    await db.insert('exercise_instances', {'day_id': 2, 'exercise_title': 'Cable Rows', 'exercise_order': 2, 'exercise_id' : 852});
    await db.insert('exercise_instances', {'day_id': 2, 'exercise_title': 'Reverse Dumbbell Flies', 'exercise_order': 3, 'exercise_id' : 852});
    await db.insert('exercise_instances', {'day_id': 2, 'exercise_title': 'Hammer Curls', 'exercise_order': 4, 'exercise_id' : 852});
    await db.insert('exercise_instances', {'day_id': 2, 'exercise_title': 'Barbell Rows', 'exercise_order': 5, 'exercise_id' : 852});

    // // Legs
    await db.insert('exercise_instances', {'day_id': 3, 'exercise_title': 'Barbell Squats', 'exercise_order': 1, 'exercise_id' : 852});
    await db.insert('exercise_instances', {'day_id': 3, 'exercise_title': 'Romanian Deadlift', 'exercise_order': 2, 'exercise_id' : 852});
    await db.insert('exercise_instances', {'day_id': 3, 'exercise_title': 'Calf Raises', 'exercise_order': 3, 'exercise_id' : 852});
    await db.insert('exercise_instances', {'day_id': 3, 'exercise_title': 'Seated Leg Curl', 'exercise_order': 4, 'exercise_id' : 852});
    await db.insert('exercise_instances', {'day_id': 3, 'exercise_title': 'Leg Extension', 'exercise_order': 5, 'exercise_id' : 852});

    // Sets for each exercise
    // Each will just start off with 3 sets, 5-8 reps, RPE 8
    // TODO: this "3" needs to be updated to however many exercises are pre added
    for (int i = 1; i <= 15; i++){
      await db.insert('plannedSets', {
      'exercise_instance_id': i, 
      'num_sets': 3,
      'set_lower': 5,
      'set_upper': 8,
      'rpe' : 8,
      'set_order': i % 5,
    });
    }
  }

  /////////////////////////////////////////////
  // INITIAL LIST POPULATING
  // the following functions run every app opening, retrieve data from database and populates lists in memory
  Future<List<Day>> initializeSplitList() async {
    
    // TODO: allow more than one program
    // Right now, we are just allowing 1 program, but in the future, 
    // I want to expand to allow user to have multiple programs saved

    // Fetch days from the database
    final List<Map<String, dynamic>> daysData = await fetchDays(1);

    // Map the database rows to day objects
    final List<Day> splitList = daysData.map((day) {

      return Day(
        dayOrder: day['day_order'],
        programID: 1,
        dayColor: day['day_color'],
        dayTitle: day['day_title'], 
        dayID: day['id'],
      );
    }).toList();

    return splitList;
  }

  Future<List<List<Exercise>>> initializeExerciseList() async {
    List<List<Exercise>> exerciseList = [];

    // Fetch days from the database
    List<Map<String, dynamic>> days = await fetchDays(1);

    for (var day in days){
      // for each day, fetch its corresponding exercises
      List<Map<String, dynamic>> exerciseData = await fetchExercises(day['id']);

      // map each exercise to an exercise object, return 2d list of exercises
      List<Exercise> exerciseDataList = exerciseData.map((exercise) {

        return Exercise(
          exerciseID: exercise['id'],
          dayID: exercise['day_id'],
          exerciseTitle: exercise['exercise_title'],
          //persistentNote: exercise['persistent_note'],
          exerciseOrder: exercise['exercise_order'],
        );
      }).toList();

      exerciseList.add(exerciseDataList);
    }

    // 2d list indexed exerciseList[day][exercise] to retrieve data
    return exerciseList;
  }

  Future<List<List<List<PlannedSet>>>> initializeSetList() async {
    List<List<List<PlannedSet>>> setList = [];

    List<Map<String, dynamic>> days = await fetchDays(1);

    // initialize 3d list indexed setList[day][exercise][set] to get data
    for (int i = 0; i < days.length; i++){//(var day in days){
      setList.add([]);
      List<Map<String, dynamic>> exercises = await fetchExercises(days[i]['id']);
      for (int j = 0; j < exercises.length; j++){//(var exercise in exercises){
        List<Map<String, dynamic>> setData = await fetchPlannedSets(exercises[j]['id']);

        List<PlannedSet> setDataList = setData.map((aSet) {

          return PlannedSet(

            exerciseID: aSet['exercise_instance_id'],
            numSets: aSet['num_sets'],
            setLower: aSet['set_lower'],
            setUpper: aSet['set_upper'],
            setID: aSet['id'],
            setOrder: aSet['set_order'],
            rpe: aSet['rpe'],

          );
        }).toList();

        setList[i].add(setDataList);
      }
    }
    return setList;
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
  // exercise TABLE CRUD

  Future<int> insertExercise({required int dayId, required String exerciseTitle, String persistentNote = '', required int exerciseOrder}) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('exercise_instances', {
      'day_id': dayId,
      'exercise_title': exerciseTitle,
      //'persistent_note': persistentNote,
      'exercise_order': exerciseOrder,
      //'exercise_id' : exercise
    });
  }

  Future<List<Map<String, dynamic>>> fetchExercises(int dayId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'exercise_instances',
      where: 'day_id = ?',
      whereArgs: [dayId],
      orderBy: 'exercise_order ASC',
    );
  }

  Future<int> updateExercise(int exerciseID, Map<String, dynamic> updatedValues) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'exercises',
      updatedValues,
      where: 'id = ?',
      whereArgs: [exerciseID],
    );
  } 

  Future<int> deleteExercise(int exerciseId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'exercises',
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
  }

  // TODO: make naming better of exercises vs exercise instances in methods
  Future<List<String>> fetchExerciseTitlesFromAll() async {
    final db = await DatabaseHelper.instance.database;
    debugPrint('Querying exercises...');  
    final result = await db.query(
      'exercises',
    );
    List<String> exercises = result.map((e) => e['exercise_title'] as String).toList();

    return exercises;
  }



  Future<int> insertCustomExercise({required String exerciseTitle, String  persistentNote = '', String musclesWorked = ''}) async {
      final db = await DatabaseHelper.instance.database;
      return await db.insert('exercises', {
        'exercise_title': exerciseTitle,
        'persistent_note': persistentNote,
        'muscles_worked' : musclesWorked
        //'exercise_id' : exercise
      });
  }

  ////////////////////////////////////////////////////////////
  // PLANNED SET TABLE CRUD


/*
id INTEGER PRIMARY KEY AUTOINCREMENT,
        DONE num_sets INTEGER NOT NULL,
        DONE set_lower INTEGER NOT NULL,
        DONE set_upper INTEGER NOT NULL,
        DONE exercise_instance_id INTEGER NOT NULL,
        DONEset_order INTEGER NOT NULL,
         DONErpe INTEGER NOT NULL,
        FOREIGN KEY (exercise_instance_id) REFERENCES exercise_instances (id) ON DELETE CASCADE
      );
*/
  Future<int> insertPlannedSet(int exerciseId, int numSets, int setLower, int setUpper, int setOrder, int? rpe) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('plannedSets', {
      'exercise_instance_id': exerciseId,
      'num_sets': numSets,
      'set_lower': setLower,
      'set_upper': setUpper,
      'set_order': setOrder,
      'rpe': rpe ?? 0,
    });
  }

  Future<List<Map<String, dynamic>>> fetchPlannedSets(int exerciseId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'plannedSets',
      where: 'exercise_instance_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'set_order ASC',
    );
  }

  Future<int> updatePlannedSet(int plannedSetId, Map<String, dynamic> updatedValues) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'plannedSets',
      updatedValues,
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
      'exercise_id': exerciseId,
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
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      //TODO: parse date and order by date
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