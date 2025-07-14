// Helper class to manage database

// On startup (open app for first time):
//  - creates tables
//  - loads exercises from txt file into DB
//  - inserts initial example program

// On opening app everytime after first time:
//  - Providers use fetch methods from this class to load data to memory

// Also provides methods to perform CRUD operations on the DB during app session
// Methods *may* not exhaust all possible CRUD operations - I tried to make methods for pretty much everything though
// methods are fitted to what the app specifically needs

// **NOTE some tables track weight. this defaults to POUNDS (LBS). 
// If the user wants to use metric, a flag will be stored in user_settings
// And values will be converted upon returning from fetch if indicated by useMetric function flag

import 'package:firstapp/other_utilities/events.dart';
import 'package:firstapp/other_utilities/format_weekday.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/providers_and_settings/program_provider.dart';
import 'profile.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'dart:math'; // For random variations
import '../other_utilities/day_of_week.dart';
import 'package:firstapp/other_utilities/time_strings.dart';
import 'package:firstapp/other_utilities/unit_conversions.dart';


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

  // this is to store any user preferences - current program, maybe if theres an active workout, etc. 
  // kinda just miscellaneous things that need to be persisted
  // this will probably be a single-record table

  // hmm so 'on workout start' I can set most recent workout to selected, and is_mid_workout to true
  // and maybe the workout icon should glow or something
  // and the timer should run even in the background
  // and then if the user closes the app, then we can check the following on opening: 
  // if a workkout is in progress, and if so, which workout it was, and what the last logged set was. 
  // then, we allow them to resume the workout, and put them at the set after the most recently logged one
  // then as the user
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
        gear TEXT NOT NULL,
        day_order INTEGER NOT NULL,
        program_id INTEGER NOT NULL,
        day_color INTEGER NOT NULL,
        workout_time TEXT,
        FOREIGN KEY (program_id) REFERENCES programs (id) ON DELETE CASCADE
      );
    '''
    );

    await db.execute(
    '''
      CREATE TABLE exercise_instances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_order INTEGER NOT NULL,
        notes TEXT NOT NULL,
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
        rpe REAL NOT NULL,
        FOREIGN KEY (exercise_instance_id) REFERENCES exercise_instances (id) ON DELETE CASCADE
      );
    '''
    );

    // might want to remove on delete cascade, or make another way to save data even if typo, or used in different workouts
    // basically, this may become a many-to-many table and we may have to have a large table of all exercises saved 
    // but for now this works
    // will be assigned session_id based off of timestamp of session to group same exercise sets done on same day
    // okay Ive decided that every set will be logged individually and will be consolidated in the DB query
    // this comes after I learnt that SQL "GROUP BY" exists lol
    // because of using groupby and this is gonna likely be the biggest table especially over time, I have added indices to hopefully speed it up
    // though in my limited testing, the queries are pretty fast either way.
    await db.execute(
    '''
      CREATE TABLE set_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        date TEXT NOT NULL,
        num_sets INTEGER NOT NULL,
        reps REAL NOT NULL,
        weight REAL NOT NULL,
        rpe REAL NOT NULL,
        history_note TEXT NOT NULL,
        exercise_id INTEGER NOT NULL,
        program_title TEXT NOT NULL,
        day_title TEXT NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      );

    '''
    );

    // Commonly used filters when looking for history so I put indices on em
    // These are the only two indices in the DB
    await db.execute('''
      CREATE INDEX idx_set_log_grouping
        ON set_log(exercise_id, reps, weight, rpe);
    ''');

    await db.execute('''
      CREATE INDEX idx_set_log_dates
        ON set_log(date DESC);
    ''');

    await db.execute(
      '''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_weight REAL NOT NULL,
        exercise_id INTEGER NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      );
      '''
    );

    await db.execute(
      '''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        current_program_id INTEGER,
        theme_mode TEXT CHECK(theme_mode IN ('light', 'dark', 'system')) DEFAULT 'system',
        program_start_date TEXT, -- ISO8601 string (YYYY-MM-DD)
        program_duration_days INTEGER DEFAULT 28, -- Typical 4-week program
        is_mid_workout BOOLEAN DEFAULT 0, -- 0 = false, 1 = true
        use_metric BOOLEAN DEFAULT 0, -- Default to lbs but user can switch, data will always be stored as lbs but will be converted in UI to kgs
        last_workout_id INTEGER, -- For resume functionality
        last_workout_timestamp TEXT, -- When they paused
        rest_timer_seconds INTEGER DEFAULT 90, -- Common default rest time
        enable_sound BOOLEAN DEFAULT 1,
        enable_haptics BOOLEAN DEFAULT 1,
        auto_rest_timer BOOLEAN DEFAULT 0,
        colour_blind_mode BOOLEAN DEFAULT 0,
        enable_notifications BOOLEAN DEFAULT 0,
        time_reminder INTEGER DEFAULT 30,
        is_first_time BOOLEAN DEFAULT 1,
        
        FOREIGN KEY (current_program_id) REFERENCES programs(id),
        FOREIGN KEY (last_workout_id) REFERENCES days(id)
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
          // ('Batching exercise: $name');

          batch.insert('exercises', {
            'exercise_title': name,
            'muscles_worked': category,
            'persistent_note': '',
          });
        }
      }
    }

    await batch.commit(); // Execute all inserts at once
  }



  // Add initial data to program in startup
  Future<void> _insertInitialData(Database db) async {
    final batch = db.batch();

    // Insert initial program
    batch.insert('programs', {'program_title': 'Simple PPL Split'});

    // Insert initial days for the program
    batch.insert('days', {'program_id': 1, 'day_title': 'Push', 'day_order': 0, 'day_color': Profile.colors[0].value, 'gear': ''});
    batch.insert('days', {'program_id': 1, 'day_title': 'Pull', 'day_order': 1, 'day_color': Profile.colors[1].value, 'gear': ''});
    batch.insert('days', {'program_id': 1, 'day_title': 'Legs', 'day_order': 2, 'day_color': Profile.colors[2].value, 'gear': ''});

    // Insert initial exercises for each day

    // Push
    batch.insert('exercise_instances', {'day_id': 1, 'exercise_order': 0, 'exercise_id': 70, 'notes' : ''}); // Barbell Bench Press
    batch.insert('exercise_instances', {'day_id': 1, 'exercise_order': 1, 'exercise_id': 851, 'notes' : ''}); // Triceps Pushdown
    batch.insert('exercise_instances', {'day_id': 1, 'exercise_order': 2, 'exercise_id': 690, 'notes' : ''}); // Side Lateral Raise
    batch.insert('exercise_instances', {'day_id': 1, 'exercise_order': 3, 'exercise_id': 270, 'notes' : ''}); // Dumbbell Shoulder Press
    batch.insert('exercise_instances', {'day_id': 1, 'exercise_order': 4, 'exercise_id': 297, 'notes' : ''}); // Cable Chest Fly

    // Pull
    batch.insert('exercise_instances', {'day_id': 2, 'exercise_order': 0, 'exercise_id': 586, 'notes' : ''}); // Pullups
    batch.insert('exercise_instances', {'day_id': 2, 'exercise_order': 1, 'exercise_id': 652, 'notes' : ''}); // Seated Cable Rows
    batch.insert('exercise_instances', {'day_id': 2, 'exercise_order': 2, 'exercise_id': 620, 'notes' : ''}); // Reverse Machine Flyes
    batch.insert('exercise_instances', {'day_id': 2, 'exercise_order': 3, 'exercise_id': 335, 'notes' : ''}); // Hammer Curls
    batch.insert('exercise_instances', {'day_id': 2, 'exercise_order': 4, 'exercise_id': 103, 'notes' : ''}); // Barbell Rows

    // Legs
    batch.insert('exercise_instances', {'day_id': 3, 'exercise_order': 0, 'exercise_id': 90, 'notes' : ''}); // Barbell Squat
    batch.insert('exercise_instances', {'day_id': 3, 'exercise_order': 1, 'exercise_id': 630, 'notes' : ''}); // Romanian Deadlift
    batch.insert('exercise_instances', {'day_id': 3, 'exercise_order': 2, 'exercise_id': 780, 'notes' : ''}); // Standing Calf Raises
    batch.insert('exercise_instances', {'day_id': 3, 'exercise_order': 3, 'exercise_id': 670, 'notes' : ''}); // Seated Leg Curl
    batch.insert('exercise_instances', {'day_id': 3, 'exercise_order': 4, 'exercise_id': 434, 'notes' : ''}); // Leg Extensions

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

    // insert default settings
    batch.insert('user_settings', {
      'current_program_id': 1, // default to first program
      'theme_mode': 'system',
      'program_duration_days': 7,
      'use_metric': 0,
      'rest_timer_seconds': 90,
      'enable_sound': 1, // no sounds in the app as of currently
      'enable_haptics': 1,
      'auto_rest_timer': 0,
      'program_start_date': getDayOfCurrentWeek(1).toIso8601String(), // defaults to monday of current week
      // rest of settings default
    });

    // inserting mock data to test analytics page
    // TODO: remove for release
    // I think I should plot a first and second and potentially more sets on the same graph
    // so the line for second set will either be on top of or likely beloow the top set
    //if (kDebugMode) {
      List<String> feelings = [
        "Doc", "Grumpy", "Happy", "Sleepy", "Bashful", "Sneezy", "Dopey"
      ];
      Random random = Random();

      DateTime startDate = DateTime.now().subtract(const Duration(days: 500));
      double baseWeight = 180; // Start weight lower to simulate progression

      for (int i = 1; i <= 500; i++) {
        double weight = baseWeight + (i * 2) + random.nextInt(10) - 5; // Linear increase + noise
        int reps = 6 + random.nextInt(3) - 1; // Small variation in reps (5-7)
        int rpe = 7 + random.nextInt(3) - 1; // RPE fluctuates (6-8)

        batch.insert('set_log', {
          'id': i,
          'session_id': startDate.add(Duration(days: i)).toIso8601String(),
          'date': startDate.add(Duration(days: i)).toIso8601String(), // Dates increase over time
          'num_sets': 1,
          'reps': reps,
          'weight': weight, // Round to nearest whole number
          'rpe': rpe,
          'history_note': "Feeling ${feelings[i % feelings.length]} today.",
          'exercise_id': 70, // Hardcoded to reference "bench press - medium grip"
          'day_title' : "Bench + Upper",
          'program_title' : "Push Pull Legs Split"
        });
      }
    //}

    

    // Execute all operations in a single batch
    await batch.commit();
  }

  // this is intended to be run when a user finishes a workout
  //this takes the session buffer populated during the workout 
  // and writes all the recorded sets to the database


  /////////////////////////////////////////////
  // INITIAL LIST POPULATING
  // the following functions run every app opening, retrieve data from database and populates lists in memory
  Future<List<Day>> initializeSplitList(int programId) async {

    // Fetch days from the database
    final List<Map<String, dynamic>> daysData = await fetchDays(programId);

    // Map the database rows to day objects
    final List<Day> splitList = daysData.map((day) {
      return Day(
        dayOrder: day['day_order'],
        programID: programId,
        dayColor: day['day_color'],
        dayTitle: day['day_title'], 
        dayID: day['id'],
        workoutTime: day['workout_time'] != null 
          ? stringToTimeOfDay(day['workout_time']) 
          : null,
        gear: day['gear']
      );
    }).toList();

    return splitList;
  }

  Future<List<List<Exercise>>> initializeExerciseList(int programID) async {
    List<List<Exercise>> exerciseList = [];

    // Fetch days from the database
    List<Map<String, dynamic>> days = await fetchDays(programID);

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
          notes: exercise['notes']
        );
      }).toList();

      exerciseList.add(exerciseDataList);
    }

    // 2d list indexed exerciseList[day][exercise] to retrieve data
    return exerciseList;
  }

  Future<List<List<List<PlannedSet>>>> initializeSetList(int programID) async {
    List<List<List<PlannedSet>>> setList = [];

    List<Map<String, dynamic>> days = await fetchDays(programID);

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

      // 1. Restore the day with original ID
      await txn.insert(
        'days',
        day.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Restore all exercises and their sets
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        final exerciseMap = Map<String, dynamic>.from(exercise.toMap());
        exerciseMap.remove('exercise_title');
        
        
        // Insert exercise with original ID
        final exerciseId = await txn.insert(
          'exercise_instances',
          exerciseMap,
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
    });
  }

  // this is for undo delete of an exercise - inserting back list of planned sets

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
  // USER SETTINGS TABLE CRUD

  // Initialize default settings (call this when first creating the database)
  Future<void> initializeDefaultSettings() async {
    final existing = await fetchUserSettings();
    if (existing == null) {
      await insertUserSettings(UserSettings());
    }
  }

  // Create/insert settings (there should only be one row)
  Future<int> insertUserSettings(UserSettings settings) async {
    final db = await database;
    return await db.insert('user_settings', settings.toMap());
  }

  // Get the user settings (there should only be one)
  Future<UserSettings?> fetchUserSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_settings', limit: 1);
    
    // this'll never happen... surely
    if (maps.isEmpty) {
      return null;
    }
    
    return UserSettings.fromMap(maps.first);
  }

  // update settings
  Future<int> updateUserSettings(UserSettings settings) async {
    final db = await database;
    debugPrint("settings: ${settings}");
    return await db.update(
      'user_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  // helper to update specific settings without fetching first
  Future<int> updateSettingsPartial(Map<String, dynamic> updates) async {
    final db = await database;
    // get the existing ID
    final settings = await fetchUserSettings();
    if (settings == null) {
      throw Exception('No settings found to update');
    }
    
    return await db.update(
      'user_settings',
      updates,
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  // delete settings (probably won't need this)
  Future<int> deleteUserSettings(int id) async {
    final db = await database;
    return await db.delete(
      'user_settings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> getThemeMode() async {
    final settings = await fetchUserSettings();
    return settings?.themeMode ?? 'system';
  }

  Future<void> setThemeMode(String themeMode) async {
    assert(['light', 'dark', 'system'].contains(themeMode));
    await updateSettingsPartial({
      'theme_mode': themeMode,
    });
  }


  // for analytics pageview -- gets dates of last performed workout for each workout
  Future<List<DateTime?>> getRecentWorkoutDates(List<Day> split) async {
    final db = await database;
    List<DateTime?> dates = [];
    final today = DateTime.now();
    List<List<Map<String, Object?>>> rawDates = [];
    // this could be a transaction but I think thats highhey overkill and silly for like 10 items
    // TODO: match on DB ID, its a bit complicated cuz we want to be able to delete days and not have foreign key errors, instead of dayTitle
    for (Day day in split) {
      rawDates.add(await db.rawQuery('''
        SELECT date
        FROM set_log
        WHERE day_title = ?
        AND date BETWEEN ? AND ?
        ORDER BY date DESC
        LIMIT 1
      ''', [day.dayTitle, today.subtract(const Duration(days: 7)).toIso8601String(), today.toIso8601String()]));
    }

    // debugPrint("raw: ${rawDates}");

    // this should maintain order, which is important since dates[i] is expected to correspond to split[i]
    for (List<Map<String, Object?>> rawDate in rawDates){
      if (rawDate.isEmpty){
        // null to indicate no workout in last 7 days
        dates.add(null);
      } else{
        // since we had limit 1 we will only have 1 record
        dates.add(DateTime.tryParse(rawDate[0]['date'] as String));
      }
    }
    return dates;
  }

  ////////////////////////////////////////////////////////////
  // GOAL TABLE CRUD

  // Create a goal
  Future<int> insertGoal(Goal goal, {useMetric = false}) async {
    // If given as kg, convert to lbs then store
    if (useMetric){
      goal = goal.copyWith(targetWeight: kgToLb(kilograms: goal.targetWeight.toDouble()));
    }

    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  // Get all goals with progress
  Future<List<Goal>> fetchGoalsWithProgress({useMetric = false}) async {
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
          : 0.0;

      
      
      goals.add(Goal(
        id: goalData['id'] as int?,
        exerciseId: exerciseId,
        exerciseTitle: goalData['exercise_title'] as String,
        targetWeight: goalData['goal_weight'] as double,
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
  double _calculateOneRm(double weight, double reps) {
    return (weight * (1 + (reps / 30)));
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

  Future<int> getCurrentProgramId() async {
    final db = await database;
    final maps = await db.query('user_settings', limit: 1);
    if (maps.isEmpty) return -1;
    return maps.first['current_program_id'] as int? ?? -1;
  }

  Future<void> setCurrentProgramId(int programId) async {
    final db = await database;
    await db.update(
      'user_settings',
      {'current_program_id': programId},
      where: 'id = 1', // Assuming single row
    );
  }

  Future<int> insertProgram(String programTitle) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('programs', {'program_title': programTitle});
  }

  Future<List<Map<String, dynamic>>> fetchPrograms() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('programs');
  }

  Future<int> updateProgram(Program program) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'programs',
      {'program_title': program.programTitle},
      where: 'id = ?',
      whereArgs: [program.programID],
    );
  }

  // this is a bit more complicated that just deleting the program, 
  //since we reference active program in user settings, and we want there to always be a program
  // so heres how it goes: 
  // if the program to delete is the one that is active, we try to set the current program to the first available program 
  // if we are deleting the final program, we add a new program called "new program", and set the current program to that
  // if we are not deleting the active program we can just delete it with no worries.
  Future<void> deleteProgram(int programId) async {
    final db = await DatabaseHelper.instance.database;
    // check if the program to be deleted is the currently active program.
    final List<Map<String, dynamic>> userSettings = await db.query(
      'user_settings',
      columns: ['current_program_id', 'id'],
      limit: 1,
    );
    debugPrint("userSettings found: ${userSettings}");

    int? currentProgramId = userSettings.isNotEmpty
        ? userSettings.first['current_program_id'] as int?
        : null;
    debugPrint("currentprogramID: ${currentProgramId}");

    if (currentProgramId == programId) {
      // The program to be deleted is the active program.

      // attempt to find another program to set as active.
      final List<Map<String, dynamic>> otherPrograms = await db.query(
        'programs',
        columns: ['id'],
        where: 'id != ?',
        whereArgs: [programId],
        limit: 1,
      );
      debugPrint("other Program candidates: ${currentProgramId}");


      if (otherPrograms.isNotEmpty) {
        // found another program: update user settings to use it.
        final int newActiveProgramId = otherPrograms.first['id'] as int;
        debugPrint("trying to set new active program to: ${newActiveProgramId}");
        debugPrint("with usersettings: ${userSettings.first['id']}");
        await db.update(
          'user_settings',
          {'current_program_id': newActiveProgramId},
          where: 'id = ?',
          whereArgs: [userSettings.first['id']],
        );
      } else {
        // no other programs exist: create a new default program and set it as active.
        final newProgramID = await insertProgram("New Program");
        await updateSettingsPartial({'current_program_id' : newProgramID});
      }
    }

    // finally, delete the requested program.  This will cascade to other tables as defined.
    await db.delete(
      'programs',
      where: 'id = ?',
      whereArgs: [programId],
    );
  }

  Future<Program> fetchProgramById(int programId) async {
    final db = await DatabaseHelper.instance.database;
    
      final List<Map<String, dynamic>> maps = await db.query(
        'programs',
        where: 'id = ?',
        whereArgs: [programId],
        limit: 1,
      );

      // if (maps.isEmpty) {
      //   return null; // No program found with this ID
      // }

      return Program.fromMap(maps.first);
    // } catch (e) {
    //   // I dont really see this ever happening, unless DB gets corrupted or user-deleted
    //   // but then again, of course I wouldnt I guess
    //   ('Error fetching program by ID: $e');
    //   return Program(programID: -1, programTitle: "Error");
    // }
  }

  Future<Program> initializeProgram() async {

    int programID = await getCurrentProgramId();
    if (programID == -1){
      programID = await insertProgram("New Program");
      setCurrentProgramId(programID);
    }
    return fetchProgramById(programID);
    
  }

  ////////////////////////////////////////////////////////////
  // DAY TABLE CRUD

  // by default, it will assign a new ID to the day.
  // but if re-adding (ie. undo a day delete), need to add with existing ID to re-link with exercises
  Future<int> insertDay({required int programId, required String dayTitle, required int dayOrder, int? id, String gear = ''}) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('days', {
      if (id != null) 'id': id,
      'program_id': programId,
      'day_title': dayTitle,
      'day_order': dayOrder,
      'day_color': Profile.colors[dayOrder % (Profile.colors.length - 1)].value,
      'gear' : gear,
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

  Future<int> insertExercise({required int dayID, required int exerciseOrder, required int exerciseID, int? id, String notes = ''}) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('exercise_instances', {
      if (id != null) 'id': id,
      'day_id': dayID,
      'exercise_order': exerciseOrder,
      'exercise_id' : exerciseID,
      'notes': notes
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
    final result = await db.query(
      'exercises',
    );
    List<String> exercises = result.map((e) => e['exercise_title'] as String).toList();

    return exercises;
  }

  // exercises are in reverse alphabetical order, and user added exercises are added at the end
  // when we query we reverse order to maintain alphabetical for preadded but also put user added ones at the top
  Future<List<Map<String, dynamic>>> fetchExercisesWithIds() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'exercises',
      columns: ['id', 'exercise_title'],
      orderBy: 'id DESC',
    );

    return result;
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
  Future<int> insertPlannedSet(int exerciseId, int numSets, int setLower, int setUpper, int setOrder, double? rpe, int? id) async {

    final db = await DatabaseHelper.instance.database;
    return await db.insert('plannedSets', {
      if (id != null) 'id': id,
      'exercise_instance_id': exerciseId,
      'num_sets': numSets,
      'set_lower': setLower,
      'set_upper': setUpper,
      'set_order': setOrder,
      'rpe': rpe ?? 0.0,
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

  Future<int> updateSetNotes({
    required String sessionId,
    required int exerciseId,
    required String note,
  }) async {
    final db = await database;
    
    return await db.update(
      'set_log',
      {
        'history_note': note,
        // Optionally update timestamp if needed:
        // 'date': DateTime.now().toIso8601String(),
      },
      where: 'session_id = ? AND exercise_id = ?',  // Both conditions
      whereArgs: [sessionId, exerciseId],          // Match both IDs
    );
  }

  Future<int> insertSetRecord(SetRecord record, {useMetric = false}) async {
    final db = await DatabaseHelper.instance.database;
    if (useMetric){
      record = record.copyWith(weight: kgToLb(kilograms: record.weight));
    }
    return await db.insert(
      'set_log', 
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // probably should use this... lol -- will be very big
  // use the pagination version that also groups by session
  Future<List<Map<String, dynamic>>> fetchAllSetRecords({required int exerciseId, int? lim}) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'set_log',

      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'datetime(date) DESC',
      limit: lim, // number of records returned
    );
  }

  // This is an optimized method for fetching data to be graphed in analytics
  // - only gets required columns
  // - filters and only gets graph timespan
  // - fetches the maximum estimated 1RM for each session within a given time range
  // - for a specific exercise.
  // - results are ordered chronologically.
  Future<List<Map<String, dynamic>>> fetchSessionMaxE1RM({
    required int exerciseId,
    required DateTime startDate,
  }) async {
    //debugPrint(startDate.toIso8601String());

    final db = await instance.database;
    // The query calculates the estimated 1RM for each set,
    // then groups by session_id and date to find the maximum e1RM within each session.
    // It filters by exercise ID and date range.
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT
        date,
        MAX(weight * (1.0 + (reps + (10.0 - rpe)) / 30.0)) AS max_e1rm_pounds -- Calculate max e1rm using the Epley formula
      FROM set_log
      WHERE exercise_id = ? AND datetime(date) >= datetime(?)
      GROUP BY session_id -- Group by session to get one data point per session
      ORDER BY datetime(date) ASC; -- Order sessions chronologically
    ''', [exerciseId, startDate.toIso8601String()]); // Use ISO8601 string for datetime comparison

    return result;
  }

  // Get ALL history of an exercise, grouped by session.
  /// See [DatabaseHelper.fetchSessionsPage] for this exact implementation but with pagination
  Future<List<List<SetRecord>>> getExerciseHistoryGroupedBySession(int exerciseId, {useMetric = false}) async {
    final db = await DatabaseHelper.instance.database;
    
    // First get all sessions for this exercise ordered by date
    final sessions = await db.rawQuery('''
      SELECT DISTINCT session_id, MAX(datetime(date)) as session_date
      FROM set_log
      WHERE exercise_id = ?
      GROUP BY session_id
      ORDER BY session_date DESC
    ''', [exerciseId]);

    // Then process each session to get consolidated sets
    final List<List<SetRecord>> result = [];
    
    for (final session in sessions) {
      final sessionId = session['session_id'] as String;
      //this is grouped by session

      // okay this is a crazy query, at least for me. lemme explain: 
      /*
      every set is logged individually, so if I do three sets of 200lbs on bench for 6 reps, RPE 9,
      ^ this gets stored as three rows. for viewing, though, I want to consolidate this and just say 3x {200lbs blah blah}
      thats what this query does with the COUNT. 
      the rest is managing the date and history note of the returned record,
      which is the info from the most recent set.
      so if you have 3 sets in the same session, it will show the history note only from the most recent one
      which is what I think people want anyways, the note should be for all three.
      */
      final sets = await db.rawQuery('''
        SELECT 
          reps,
          weight,
          rpe,
          COUNT(*) as num_sets,
          exercise_id,
          session_id,
          day_title,
          program_title,
          MAX(datetime(date)) as date,
          (
            SELECT history_note 
            FROM set_log AS s2 
            WHERE s2.reps = set_log.reps 
              AND s2.weight = set_log.weight 
              AND s2.rpe = set_log.rpe 
              AND s2.exercise_id = set_log.exercise_id
              AND s2.session_id = ?
            ORDER BY datetime(date) ASC 
            LIMIT 1
          ) as history_note,
          (
            SELECT id
            FROM set_log AS s3
            WHERE s3.reps = set_log.reps
              AND s3.weight = set_log.weight
              AND s3.rpe = set_log.rpe
              AND s3.exercise_id = set_log.exercise_id
              AND s3.session_id = ?
            ORDER BY datetime(date) ASC
            LIMIT 1
          ) as record_id
        FROM set_log
        WHERE exercise_id = ? AND session_id = ?
        GROUP BY reps, weight, rpe
        ORDER BY datetime(date) ASC
      ''', [sessionId, sessionId, exerciseId, sessionId]);

      result.add(sets.map((r) => SetRecord(

        reps: r['reps'] as double,
        weight: useMetric ? lbToKg(pounds: r['weight'] as double): r['weight'] as double,
        rpe: r['rpe'] as double,
        numSets: r['num_sets'] as int,
        sessionID: r['session_id'] as String,
        exerciseID: r['exercise_id'] as int,
        date: r['date'] as String,
        historyNote: r['history_note'] as String? ?? '',
        recordID: r['record_id'] as int,
        dayTitle: r['day_title'] as String,
        programTitle: r['program_title'] as String,
      )).toList());
    }

    return result;
  }

  /// Fetches a single page of sessions for a specific exercise, ordered by date descending.
  /// For each session in the page, it also fetches the consolidated sets.
  /// Returns null if no sessions are found for the given limit/offset.
  Future<List<List<SetRecord>>?> fetchSessionsPage({
    required int exerciseId,
    required int limit,
    required int offset,
    bool useMetric = false,
  }) async {
    final db = await instance.database;

    // First, get a page of sessions for this exercise ordered by date
    final sessionsPage = await db.rawQuery('''
      SELECT DISTINCT session_id, MAX(datetime(date)) as session_date
      FROM set_log
      WHERE exercise_id = ?
      GROUP BY session_id
      ORDER BY session_date DESC
      LIMIT ? OFFSET ?
    ''', [exerciseId, limit, offset]);

    if (sessionsPage.isEmpty) {
      return null; // No more sessions to load
    }

    // Then process each session in the page to get consolidated sets
    final List<List<SetRecord>> result = [];

    for (final session in sessionsPage) {
      final sessionId = session['session_id'] as String;

      // Query to get consolidated sets for a specific session
      final sets = await db.rawQuery('''
        SELECT
          reps,
          weight,
          rpe,
          COUNT(*) as num_sets,
          exercise_id,
          session_id,
          day_title,
          program_title,
          MAX(datetime(date)) as date, -- Use MAX date for the consolidated set entry
          (
            SELECT history_note
            FROM set_log AS s2
            WHERE s2.reps = set_log.reps
              AND s2.weight = set_log.weight
              AND s2.rpe = set_log.rpe
              AND s2.exercise_id = set_log.exercise_id
              AND s2.session_id = ?
            ORDER BY datetime(date) ASC
            LIMIT 1
          ) as history_note,
          (
            SELECT id
            FROM set_log AS s3
            WHERE s3.reps = set_log.reps
              AND s3.weight = set_log.weight
              AND s3.rpe = set_log.rpe
              AND s3.exercise_id = set_log.exercise_id
              AND s3.session_id = ?
            ORDER BY datetime(date) ASC
            LIMIT 1
          ) as record_id -- ID of the most recent set in this consolidated group
        FROM set_log
        WHERE exercise_id = ? AND session_id = ?
        GROUP BY reps, weight, rpe
        ORDER BY datetime(date) ASC -- Order sets within the session? Or by weight/reps? Let's keep date desc consistent with session order.
                                     -- Note: GROUP BY means the order might not be perfectly predictable without an outer order on reps/weight/rpe, but MAX(date) helps.
      ''', [sessionId, sessionId, exerciseId, sessionId]);

      result.add(sets.map((r) => SetRecord(
        reps: r['reps'] as double,
        weight: useMetric ? lbToKg(pounds: r['weight'] as double): r['weight'] as double,
        rpe: r['rpe'] as double,
        numSets: r['num_sets'] as int,
        sessionID: r['session_id'] as String,
        exerciseID: r['exercise_id'] as int,
        date: r['date'] as String,
        historyNote: r['history_note'] as String? ?? '',
        recordID: r['record_id'] as int,
        dayTitle: r['day_title'] as String,
        programTitle: r['program_title'] as String,
      )).toList());
    }

    return result;
  }

  // this is the same as above, but is used for only one session past history for during workout quick check.
  Future<List<SetRecord>> getPreviousSessionSets(int exerciseId, String currentSessionID, {useMetric = false}) async {
    final db = await DatabaseHelper.instance.database;
  //debugPrint("sessionID: $currentSessionID");
    final results = await db.rawQuery('''
      WITH recent_sessions_with_exercise AS (
        SELECT session_id
        FROM set_log
        WHERE session_id != ? -- Exclude current session
          AND exercise_id = ? 
        GROUP BY session_id
        ORDER BY MAX(date) DESC
        LIMIT 1
      )
      SELECT
        reps,
        weight,
        rpe,
        day_title,
        program_title,
        COUNT(*) as num_sets,
        MAX(date) as date,
        (
          SELECT history_note
          FROM set_log AS s2
          WHERE s2.reps = set_log.reps
            AND s2.weight = set_log.weight
            AND s2.rpe = set_log.rpe
            AND s2.session_id IN (SELECT session_id FROM recent_sessions_with_exercise) -- Use updated CTE
          ORDER BY date ASC
          LIMIT 1
        ) as history_note,
        (
          SELECT session_id FROM recent_sessions_with_exercise LIMIT 1 -- More direct way to get this
        ) as session_id,
        ? as exercise_id,
        (
          SELECT id
          FROM set_log AS s4
          WHERE s4.reps = set_log.reps
            AND s4.weight = set_log.weight
            AND s4.rpe = set_log.rpe
            AND s4.session_id IN (SELECT session_id FROM recent_sessions_with_exercise) -- Use updated CTE
          ORDER BY date ASC
          LIMIT 1
        ) as record_id
      FROM set_log
      WHERE exercise_id = ? -- Main filter for the specific exercise
        AND session_id IN (SELECT session_id FROM recent_sessions_with_exercise) -- Link to the found session
      GROUP BY reps, weight, rpe -- Group sets within that found session and exercise
      ORDER BY date ASC;
    ''', [currentSessionID, exerciseId, exerciseId, exerciseId]);

    return results.map((r) => SetRecord(
      reps: r['reps'] as double,
      weight: useMetric ? lbToKg(pounds: r['weight'] as double): r['weight'] as double,
      rpe: r['rpe'] as double,
      numSets: r['num_sets'] as int,
      sessionID: r['session_id'] as String,
      exerciseID: r['exercise_id'] as int,
      date: r['date'] as String,
      historyNote: r['history_note'] as String? ?? '',
      recordID: r['record_id'] as int,
      dayTitle: r['day_title'] as String,
      programTitle: r['program_title'] as String,
    )).toList();
  }

  // egts all sets that were logged during a day  
  Future<List<SetRecord>> getSetsForDay(DateTime day, {useMetric = false}) async {

    final db = await DatabaseHelper.instance.database;
    final results = await db.rawQuery('''
      SELECT 
        *,
        COUNT(*) as num_sets
      FROM set_log
      WHERE date BETWEEN ? AND ?
      GROUP BY exercise_id, reps, weight, rpe
      ORDER BY date, exercise_id
    ''', [DateTime(day.year, day.month, day.day).toIso8601String(), DateTime(day.year, day.month, day.day).add(const Duration(days: 1)).toIso8601String()]);

    // debugPrint("raw results: ${results}");

    return results.map((r) => SetRecord(
      reps: r['reps'] as double,
      weight: useMetric ? lbToKg(pounds: r['weight'] as double): r['weight'] as double,
      rpe: r['rpe'] as double,
      numSets: r['num_sets'] as int,
      sessionID: r['session_id'] as String,
      exerciseID: r['exercise_id'] as int,
      date: r['date'] as String,
      historyNote: r['history_note'] as String? ?? '',
      recordID: r['id'] as int,
      dayTitle: r['day_title'] as String,
      programTitle: r['program_title'] as String,
    )).toList();
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

  /// this method returns a list of days in the given range where at least one set was logged
  /// mainly for use on schedule page to mark a day as having done a workout
  Future<List<DateTime>> getDaysWithHistory (DateTime startRange, DateTime endRange) async {

    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        date
      FROM set_log
      WHERE date BETWEEN ? AND ?
      GROUP BY date
      ORDER BY date ASC
    ''', [startRange.toIso8601String(), endRange.toIso8601String()]);

    return maps.map((date) {
      return normalizeDay(DateTime.parse(date['date']));
    }).toList();


  }
  // close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}