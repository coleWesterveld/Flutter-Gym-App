import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/user.dart';
import 'profile.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
// TODO: maybe add way to delete added exercises
//TODO: set data not saving currently for some reason
// database helper for interfacing with SQLite database
// setup tables, CRUD operations, initialization
// TODO: maybe switch some integers to real to allow decimals. ie weight and even reps

// TODO: unify ordering index start
// currently I think some start at 0 and some at 1
// it technically doesnt matter since its all relative but just weird
// in inserting, we do not want to use the Day or Exercise objects since they require an ID which we dont have prior to inserting
// unless we want to make that optional I guess but I think it would be better to not
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

    await db.execute(
    '''
      CREATE TABLE exercise_instances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_order INTEGER NOT NULL,
        day_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE,
        FOREIGN KEY (day_id) REFERENCES days (id) ON DELETE CASCADE
      );
    '''
    );

    // TODO: maybe add support for more than 1 muscle worked - will require schema changes to not violate 1NF
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
    // will be assigned session_id based off of timestamp of session to group same exercise sets done on same day
    await db.execute(
    '''
      CREATE TABLE set_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        date TEXT NOT NULL,
        numSets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight INTEGER NOT NULL,
        rpe INTEGER NOT NULL,
        history_note TEXT NOT NULL,
        exercise_id INTEGER NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      );
    '''
    );

    // load all excercises from text file into database
    await _loadExercisesFromText(db);

    // Insert initial data - simple push pull legs split on run after download, easily editable by user
    await _insertInitialData(db);

  }

  // Runs on startup - loads all exercises from a text file into the database
  Future<void> _loadExercisesFromText(Database db) async {
    final data = await rootBundle.loadString('assets/exercises.txt');
    final lines = data.split('\n');

    final batch = db.batch(); // Start a batch

    for (var line in lines) {
      if (line.trim().isNotEmpty) {
        final parts = line.split(',');
        if (parts.length >= 2) {
          final name = parts[0].trim();
          final category = parts[1].trim();
          // debugPrint('Batching exercise: $name');

          batch.insert('exercises', {
            'exercise_title': name,
            'muscles_worked': category,
            'persistent_note': '',
          });
        }
      }
    }

    await batch.commit(); // Execute all inserts at once
    debugPrint("Done Initial Insert");
  }



  // Add initial data to program in startup
  Future<void> _insertInitialData(Database db) async {
    final batch = db.batch();

    // Insert initial program
    batch.insert('programs', {'program_title': 'Program1'});

    // Insert initial days for the program
    batch.insert('days', {'program_id': 1, 'day_title': 'Push', 'day_order': 0, 'day_color': Profile.colors[0].value});
    batch.insert('days', {'program_id': 1, 'day_title': 'Pull', 'day_order': 1, 'day_color': Profile.colors[1].value});
    batch.insert('days', {'program_id': 1, 'day_title': 'Legs', 'day_order': 2, 'day_color': Profile.colors[2].value});

    // Insert initial exercises for each day

    // Push
    batch.insert('exercise_instances', {'day_id': 1, 'exercise_order': 0, 'exercise_id': 70}); // Barbell Bench Press
    batch.insert('exercise_instances', {'day_id': 1, 'exercise_order': 1, 'exercise_id': 851}); // Triceps Pushdown
    batch.insert('exercise_instances', {'day_id': 1, 'exercise_order': 2, 'exercise_id': 690}); // Side Lateral Raise
    batch.insert('exercise_instances', {'day_id': 1, 'exercise_order': 3, 'exercise_id': 270}); // Dumbbell Shoulder Press
    batch.insert('exercise_instances', {'day_id': 1, 'exercise_order': 4, 'exercise_id': 297}); // Cable Chest Fly

    // Pull
    batch.insert('exercise_instances', {'day_id': 2, 'exercise_order': 0, 'exercise_id': 586}); // Pullups
    batch.insert('exercise_instances', {'day_id': 2, 'exercise_order': 1, 'exercise_id': 652}); // Seated Cable Rows
    batch.insert('exercise_instances', {'day_id': 2, 'exercise_order': 2, 'exercise_id': 620}); // Reverse Machine Flyes
    batch.insert('exercise_instances', {'day_id': 2, 'exercise_order': 3, 'exercise_id': 335}); // Hammer Curls
    batch.insert('exercise_instances', {'day_id': 2, 'exercise_order': 4, 'exercise_id': 103}); // Barbell Rows

    // Legs
    batch.insert('exercise_instances', {'day_id': 3, 'exercise_order': 0, 'exercise_id': 90}); // Barbell Squat
    batch.insert('exercise_instances', {'day_id': 3, 'exercise_order': 1, 'exercise_id': 630}); // Romanian Deadlift
    batch.insert('exercise_instances', {'day_id': 3, 'exercise_order': 2, 'exercise_id': 780}); // Standing Calf Raises
    batch.insert('exercise_instances', {'day_id': 3, 'exercise_order': 3, 'exercise_id': 670}); // Seated Leg Curl
    batch.insert('exercise_instances', {'day_id': 3, 'exercise_order': 4, 'exercise_id': 434}); // Leg Extensions

    // Sets for each exercise (3 sets, 5-8 reps, RPE 8)
    for (int i = 1; i <= 15; i++) {
      batch.insert('plannedSets', {
        'exercise_instance_id': i,
        'num_sets': 3,
        'set_lower': 5,
        'set_upper': 8,
        'rpe': 8,
        'set_order': 0,
      });
    }

    // Execute all operations in a single batch
    await batch.commit();
  }

  // this is intended to be run when a user finishes a workout
  //this takes the session buffer populated during the workout 
  // and writes all the recorded sets to the database
  Future<void> insertSetRecords(Database db, List<SetRecord> records) async {
    if (records.isEmpty) return;

    await db.transaction((txn) async {
      final Batch batch = txn.batch();

      for (var record in records) {
        batch.insert(
          'set_log',
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace, // Avoid duplicates
        );
      }

      await batch.commit(noResult: true); // Improves performance by not returning results
    });
  }


  /////////////////////////////////////////////
  // INITIAL LIST POPULATING
  // the following functions run every app opening, retrieve data from database and populates lists in memory
  Future<List<Day>> initializeSplitList() async {
    
    // TODO: allow more than one program
    // Right now, we are just allowing 1 program, but in the future, 
    // I want to expand to allow user to have multiple programs saved

    // Fetch days from the database
    final List<Map<String, dynamic>> daysData = await fetchDays(1/*only one program - program 1 for now*/);

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
      // TODO: join title to exercise instance
      List<Map<String, dynamic>> exerciseData = await fetchExerciseInstances(day['id']);

      // map each exercise to an exercise object, return 2d list of exercises
      List<Exercise> exerciseDataList = exerciseData.map((exercise) {

        return Exercise(
          exerciseID: exercise['id'],
          dayID: exercise['day_id'],
          exerciseTitle: exercise['exercise_title'],
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
      List<Map<String, dynamic>> exercises = await fetchExerciseInstances(days[i]['id']);
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

  // this should be done using updateDay method which is a superset of this
  // Future<int> updateDayOrder(int dayId, int newOrder) async {
  //   final db = await DatabaseHelper.instance.database;
  //   return await db.update(
  //     'days',
  //     {'day_order': newOrder},
  //     where: 'id = ?',
  //     whereArgs: [dayId],
  //   );
  // }

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
  // exercise_instances TABLE CRUD

  Future<int> insertExercise({required int dayID, required int exerciseOrder, required int exerciseID}) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('exercise_instances', {
      'day_id': dayID,
      'exercise_order': exerciseOrder,
      'exercise_id' : exerciseID,
    });
  }

  // this joins the exercise instance and it's corresponding exercise to access title, persistent note and other things
  Future<List<Map<String, dynamic>>> fetchExerciseInstances(int dayId) async {
  final db = await DatabaseHelper.instance.database;
  return await db.rawQuery('''
    SELECT exercise_instances.*, exercises.exercise_title, exercises.persistent_note, exercises.muscles_worked
    FROM exercise_instances
    JOIN exercises ON exercise_instances.exercise_id = exercises.id
    WHERE exercise_instances.day_id = ?
    ORDER BY exercise_instances.exercise_order ASC
  ''', [dayId]);
}


  Future<int> updateExerciseInstance(int exerciseID, Map<String, dynamic> updatedValues) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'exercise_instances',
      updatedValues,
      where: 'id = ?',
      whereArgs: [exerciseID],
    );
  } 

  Future<int> deleteExerciseInstance(int exerciseId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'exercise_instances',
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
  }

  // fetch an exercise by ID
  Future<String> fetchExerciseTitleById(int exerciseID) async {
    final db = await database;
    final result = await db.query(
      'exercises',
      columns: ['exercise_title'],
      where: 'id = ?',
      whereArgs: [exerciseID],
    );

    if (result.isNotEmpty) {
      return result.first['exercise_title'] as String;
    } else {
      throw Exception('Exercise with id $exerciseID not found');
    }
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

  Future<List<Map<String, dynamic>>> fetchExercisesWithIds() async {
    final db = await DatabaseHelper.instance.database;
    debugPrint('Querying exercises...');

    final result = await db.query(
      'exercises',
      columns: ['id', 'exercise_title'], // Fetch only ID and title
    );

    return result; // Already in List<Map<String, dynamic>> format
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

  // TODO: add other exercise (not instances) methods
  // tbh delete and stuff shouldnt need to be used often but should add

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
    'set_log',
    where: 'exercise_id = ?',
    whereArgs: [exerciseId],
    orderBy: 'datetime(date) DESC', // Order by date in descending order
  );
}

  Future<int> updateSetRecord(
    int setRecordId, Map<String, dynamic> newValues) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'setRecord',
      newValues,
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

  // close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}