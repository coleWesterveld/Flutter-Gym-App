import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'profile.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('programs.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

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
        program_title TEXT NOT NULL
        FOREIGN KEY (program_id) REFERENCES programs (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE excercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        excercise_title TEXT NOT NULL,
        event_time TEXT NOT NULL,
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

  }

  // TODO: CRUD HERE


  // need to be able to:
  // add day of given program
  // delete day of given program
  // update day of given program
  // 

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}