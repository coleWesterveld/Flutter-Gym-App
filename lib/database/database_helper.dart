import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/user.dart';
import 'profile.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'dart:math'; // For random variations

// you may notice that I have separate methods to insert exercises, lists of exercises, and same with sets, 
// when I could just loop inserting a single exercise.
// but by using batches and transactions, this helps ensure data integrity and efficiency

/*
TODO: currently, when a user adds an exercise it shows up at the end of the query
this is not intuitive though, since if theyve gone to the effort to add it, 
they probably intend to use it, so it should be at the top. At the same time, 
I like the alphabetic order, and the record gets added to the end (I could add top start but shifting indices and stuff is slow and hard to keep track of). 
I think the best way to fix this is to reverse the order of all saved exercises, and then continue to add exercises to the end.
THEN, when the user queries, it will display in REVERSE order. Alphabetic preserved, recent adds at the top still :)
*/
// TODO: maybe add way to delete added exercises
// setup tables, CRUD operations, initialization
// TODO: maybe switch some integers to real to allow decimals. ie weight and even reps

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
        num_sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight INTEGER NOT NULL,
        rpe INTEGER NOT NULL,
        history_note TEXT NOT NULL,
        exercise_id INTEGER NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      );
    '''
    );

    db.execute(
      '''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_weight INTEGER NOT NULL,
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


    /*
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        date TEXT NOT NULL,
        num_sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight INTEGER NOT NULL,
        rpe INTEGER NOT NULL,
        history_note TEXT NOT NULL,
        exercise_id INTEGER NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      
    */
    // inserting mock data to test analytics page
    // TODO: remove for release
    // I think I should plot a first and second and potentially more sets on the same graph
    // so the line for second set will either be on top of or likely beloow the top set
    if (kDebugMode) {
      List<String> feelings = [
        "Doc", "Grumpy", "Happy", "Sleepy", "Bashful", "Sneezy", "Dopey"
      ];
      Random random = Random();

      DateTime startDate = DateTime.now().subtract(const Duration(days: 15));
      double baseWeight = 180; // Start weight lower to simulate progression

      for (int i = 1; i <= 15; i++) {
        double weight = baseWeight + (i * 2) + random.nextInt(10) - 5; // Linear increase + noise
        int reps = 6 + random.nextInt(3) - 1; // Small variation in reps (5-7)
        int rpe = 7 + random.nextInt(3) - 1; // RPE fluctuates (6-8)

        batch.insert('set_log', {
          'id': i,
          'session_id': 1234,
          'date': startDate.add(Duration(days: i)).toIso8601String(), // Dates increase over time
          'num_sets': 2,
          'reps': reps,
          'weight': weight.round(), // Round to nearest whole number
          'rpe': rpe,
          'history_note': "Feeling ${feelings[i % feelings.length]} today.",
          'exercise_id': 70 // Hardcoded to reference "bench press - medium grip"
        });
      }
    }

    

    // Execute all operations in a single batch
    await batch.commit();
  }

  // this is intended to be run when a user finishes a workout
  //this takes the session buffer populated during the workout 
  // and writes all the recorded sets to the database




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
          id: exercise['id'],
          exerciseID: exercise['exercise_id'],
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

    /// Inserts a complete day with exercises and sets in a single transaction
  Future<void> restoreDayWithContents({
  required Day day,
  required List<Exercise> exercises,
  required List<List<PlannedSet>> setsForExercises,
}) async {
  final db = await database;
  
  await db.transaction((txn) async {
    try {
      // 1. Restore the day with original ID
      await txn.insert(
        'days',
        day.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Restore all exercises and their sets
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        
        // Insert exercise with original ID
        final exerciseId = await txn.insert(
          'exercise_instances',
          exercise.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 3. Restore all sets for this exercise using direct index access
        final sets = setsForExercises[i];
        for (final set in sets) {
          await txn.insert(
            'plannedSets',
            {
              'id': set.setID, // Preserve original set ID
              'num_sets': set.numSets,
              'set_lower': set.setLower,
              'set_upper': set.setUpper,
              'exercise_instance_id': exerciseId,
              'set_order': set.setOrder,
              'rpe': set.rpe ?? 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    } catch (e) {
      debugPrint('Restore failed: $e');
      rethrow;
    }
  });
}

// this is for undo delete of an exercise - inserting back list of planned sets
//socks
Future<void> insertPlannedSetsBatch({
  required int exerciseInstanceId,
  required List<PlannedSet> sets,
}) async {
  final db = await database;
  
  await db.transaction((txn) async {
    final batch = txn.batch();
    
    for (final set in sets) {
      batch.insert(
        'plannedSets',
        {
          'id': set.setID, // Preserve original ID
          'num_sets': set.numSets,
          'set_lower': set.setLower,
          'set_upper': set.setUpper,
          'exercise_instance_id': exerciseInstanceId,
          'set_order': set.setOrder,
          'rpe': set.rpe ?? 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  });
}

  ////////////////////////////////////////////////////////////
  // GOAL TABLE CRUD

  // Create a goal
  Future<int> insertGoal(Goal goal) async {
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  // Get all goals with progress
  Future<List<Goal>> fetchGoalsWithProgress() async {
    final db = await database;
    
    // Get goals with exercise titles
    final goalsData = await db.rawQuery('''
      SELECT goals.id, goals.goal_weight, goals.exercise_id, 
             exercises.exercise_title
      FROM goals
      INNER JOIN exercises ON goals.exercise_id = exercises.id
    ''');

    // Calculate current progress for each
    final List<Goal> goals = [];
    for (var goalData in goalsData) {
      final exerciseId = goalData['exercise_id'] as int;
      
      // Get most recent set
      final recentSet = await _getMostRecentSet(exerciseId);
      
      // Calculate 1RM
      final currentOneRm = recentSet != null 
          ? _calculateOneRm(recentSet['weight'], recentSet['reps'])
          : 0;
      
      goals.add(Goal(
        id: goalData['id'] as int?,
        exerciseId: exerciseId,
        exerciseTitle: goalData['exercise_title'] as String,
        targetWeight: goalData['goal_weight'] as int,
        currentOneRm: currentOneRm,
      ));
    }

    return goals;
  }

  // Helper to get most recent set for an exercise
  Future<Map<String, dynamic>?> _getMostRecentSet(int exerciseId) async {
    final db = await database;
    final results = await db.query(
      'set_log',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'date DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Calculate 1RM using Epley formula
  int _calculateOneRm(int weight, int reps) {
    return (weight * (1 + (reps / 30)).round());
  }

  // Update a goal
  Future<int> updateGoal(Goal goal) async {
    final db = await database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // Delete a goal
  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  // by default, it will assign a new ID to the day.
  // but if re-adding (ie. undo a day delete), need to add with existing ID to re-link with exercises
  Future<int> insertDay({required int programId, required String dayTitle, required int dayOrder, int? id}) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('days', {
      if (id != null) 'id': id,
      'program_id': programId,
      'day_title': dayTitle,
      'day_order': dayOrder,
      'day_color': Profile.colors[dayOrder % (Profile.colors.length - 1)].value
    });
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

  Future<int> insertExercise({required int dayID, required int exerciseOrder, required int exerciseID, int? id}) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('exercise_instances', {
      if (id != null) 'id': id,
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
  Future<int> insertPlannedSet(int exerciseId, int numSets, int setLower, int setUpper, int setOrder, int? rpe, int? id) async {

    final db = await DatabaseHelper.instance.database;
    return await db.insert('plannedSets', {
      if (id != null) 'id': id,
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
        SetRecord record) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'set_log', 
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
      'set_log',
      newValues,
      where: 'id = ?',
      whereArgs: [setRecordId],
    );
  }

  Future<int> deleteSetRecord(int setRecordId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'set_log',
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