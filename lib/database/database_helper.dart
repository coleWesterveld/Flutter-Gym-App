import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
//import 'profile.dart';

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
    );
  }

  // create initial tables on startup
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_title TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_title TEXT NOT NULL
        FOREIGN KEY (program_id) REFERENCES programs (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE excercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        excercise_title TEXT NOT NULL,
        FOREIGN KEY (day_id) REFERENCES days (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE plannedSets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        num_sets INTEGER NOT NULL,
        set_lower INTEGER NOT NULL,
        set_upper INTEGER NOT NULL,
        FOREIGN KEY (excercise_id) REFERENCES excercises (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE setRecord (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        numSets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight INTEGER NOT NULL,
        rpe INTEGER NOT NULL,
        history_note TEXT NOT NULL,
        FOREIGN KEY (excercise_id) REFERENCES excercises (id)
      )
    ''');

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

  // close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}