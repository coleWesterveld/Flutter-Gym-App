import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firstapp/data_saving.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/user.dart';
import 'profile.dart';
//import 'profile.dart';

//TODO: add order to days, as theyre not implicity stored that way 
// it is in the table but I need to include functionality
// need to use "ORDER BY" SQL command when retrieving days so I get them in the right order
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
        program_title TEXT NOT NULL,
      );
    '''
    );

    await db.execute(
    '''
      CREATE TABLE days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_title TEXT NOT NULL,
        day_order INTEGER NOT NULL,
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
    await db.insert('days', {'program_id': 1, 'day_title': 'Push'});
    await db.insert('days', {'program_id': 1, 'day_title': 'Pull'});
    await db.insert('days', {'program_id': 1, 'day_title': 'Legs'});

    //insert initial excercises for program
    //Push
    await db.insert('excercises', {'day_id': 1, 'excercise_title': 'Bench Press'});
    await db.insert('excercises', {'day_id': 1, 'excercise_title': 'Tricep Pushdown'});
    await db.insert('excercises', {'day_id': 1, 'excercise_title': 'Lateral Raise'});
    await db.insert('excercises', {'day_id': 1, 'excercise_title': 'Shoulder Press'});
    await db.insert('excercises', {'day_id': 1, 'excercise_title': 'Cable Chest Fly'});

    //pull  
    await db.insert('excercises', {'day_id': 2, 'excercise_title': 'Weighted Pull-ups'});
    await db.insert('excercises', {'day_id': 2, 'excercise_title': 'Cable Rows'});
    await db.insert('excercises', {'day_id': 2, 'excercise_title': 'Reverse Dumbbell Flies'});
    await db.insert('excercises', {'day_id': 2, 'excercise_title': 'Hammer Curls'});
    await db.insert('excercises', {'day_id': 2, 'excercise_title': 'Barbell Rows'});

    //legs
    await db.insert('excercises', {'day_id': 3, 'excercise_title': 'Barbell Squats'});
    await db.insert('excercises', {'day_id': 3, 'excercise_title': 'Romanian Deadlift'});
    await db.insert('excercises', {'day_id': 3, 'excercise_title': 'Calf Raises'});
    await db.insert('excercises', {'day_id': 3, 'excercise_title': 'Seated Leg Curl'});
    await db.insert('excercises', {'day_id': 3, 'excercise_title': 'Leg Extension'});

    // sets for each excercise
    // each will just start off with 3 sets, 5-8 reps
    for (int i = 1; i <= 15; i++){
      await db.insert('plannedSets', {
      'excercise_id': i, 
      'num_sets': 3,
      'set_lower': 5,
      'set_upper': 8,
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
        programID: 1,
        dayTitle: day['day_title'], // Assuming 'day_title' is the column name in the database
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
      List<Map<String, dynamic>> excerciseData = await fetchExercises(day["id"]);

      List<Excercise> excerciseDataList = excerciseData.map((excercise) {
        // Example: Set `dayColor` dynamically based on the data (default to a color if none specified)

        return Excercise(
          dayID: excercise["day_id"],
          excerciseTitle: excercise["excercise_title"],
          persistentNote: excercise["persistent_note"],
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
      List<Map<String, dynamic>> excercises = await fetchExercises(days[i]["id"]);
      for (int j = 0; j < excercises.length; j++){//(var excercise in excercises){
        List<Map<String, dynamic>> setData = await fetchPlannedSets(excercises[j]["id"]);

        List<PlannedSet> setDataList = setData.map((set) {

          return PlannedSet(

            excerciseID: set["excercise_id"],
            numSets: set["num_sets"],
            setLower: set["set_lower"],
            setUpper: set["set_upper"],
            //excerciseTitle: excercise["excercise_title"],
            // persistentNote: excercise["persistent_note"],
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

  Future<int> insertDay(int programId, String dayTitle) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('days', {
      'program_id': programId,
      'day_title': dayTitle,
    });
  }

  Future<List<Map<String, dynamic>>> fetchDays(int programId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'days',
      where: 'program_id = ?',
      whereArgs: [programId],
    );
  }

  Future<int> updateDay(int dayId, String newTitle) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'days',
      {'day_title': newTitle},
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
  // EXCERCISE TABLE CRUD

  Future<int> insertExercise(int dayId, String exerciseTitle) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('excercises', {
      'day_id': dayId,
      'excercise_title': exerciseTitle,
    });
  }

  Future<List<Map<String, dynamic>>> fetchExercises(int dayId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'excercises',
      where: 'day_id = ?',
      whereArgs: [dayId],
    );
  }

  Future<int> updateExercise(int exerciseId, String newTitle) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'excercises',
      {'excercise_title': newTitle},
      where: 'id = ?',
      whereArgs: [exerciseId],
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

  Future<int> insertPlannedSet(int exerciseId, int numSets, int setLower, int setUpper) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('plannedSets', {
      'excercise_id': exerciseId,
      'num_sets': numSets,
      'set_lower': setLower,
      'set_upper': setUpper,
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