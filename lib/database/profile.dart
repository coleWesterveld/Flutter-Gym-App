
// at some point, this should be merged with Profile class in user.dart
// for now, I am setting up relational local database to store user data, 
// and so I will start fresh 
// to make it easier to follow the tutorial.
// https://www.youtube.com/watch?v=t39VV2XyqR0&t=128s
// ^ tutorial series from SmartHerd on YT, used to create this

// Also with help of the one and only ChatGPT

// PROGRAM TABLE
// (one program -> many days)
class Program {

  final int programID;
  final String programTitle;

  Program({required this.programID, required this.programTitle});

  Map<String, dynamic> toMap() {
    return {
      'programID': programID,
      'programTitle': programTitle,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      programID: map['program_id'],
      programTitle: map['program_title'],
    );
  }
  @override
  String toString() {
    return 'Program{title: $programTitle, id: $programID}';
  }
}

// DAY TABLE
// (one day -> many excercises)
class Day {
  final int dayID;
  final String dayTitle;
  final int programID;
  final int dayColor;
  int dayOrder;

  Day({required this.dayID, required this.dayTitle, required this.programID, required this.dayColor, required this.dayOrder});

  Map<String, dynamic> toMap() {
    return {
      'id': dayID,
      'day_title': dayTitle,
      'program_id': programID,
      'day_color': dayColor,
      'day_order': dayOrder,
    };
  }

  factory Day.fromMap(Map<String, dynamic> map) {
    return Day(
      dayColor: map['day_color'],
      dayID: map['day_id'],
      dayTitle: map['day_title'],
      programID: map['program_id'],
      dayOrder: map['day_order'],
    );
  }

  @override
  String toString() {
    return 'Day{title: $dayTitle, id: $dayID, prgmID: $programID, order: $dayOrder}';
  }


  Day copyWith({int? newDayColor, int? newDayID, String? newDayTitle, int? newProgramID, int? newDayOrder}) {
    return Day(
      dayOrder: newDayOrder ?? dayOrder,
      dayColor: newDayColor ?? dayColor,
      dayID: newDayID ?? dayID,
      dayTitle: newDayTitle ?? dayTitle,
      programID: newProgramID ?? programID,
    );
  }
}

// EXCERCISE TABLE
// (one excercise -> many planned sets, many set records)
class Excercise {
  final int excerciseID;
  final int dayID;
  final String excerciseTitle;
  final String? persistentNote;
  final int excerciseOrder;


  Excercise({
    required this.excerciseID, 
    required this.dayID, 
    required this.excerciseTitle, 
    required this.excerciseOrder,
    this.persistentNote
  });

  Map<String, dynamic> toMap() {
    return {
      'id': excerciseID,
      'day_id': dayID,
      'excercise_title': excerciseTitle,
      'persistent_note': persistentNote,
      'excercise_order': excerciseOrder,
    };
  }

  factory Excercise.fromMap(Map<String, dynamic> map) {
    return Excercise(
      excerciseID: map['id'],
      dayID: map['day_id'],
      excerciseTitle: map['excercise_title'],
      persistentNote: map['persistent_note'],
      excerciseOrder: map['excercise_order']
    );
  }
  @override
  String toString() {
    return 'Excercise{title: $excerciseTitle, id: $excerciseID, dayID: $dayID, persistNote: $persistentNote}';
  }

  Excercise copyWith({int? newDayID, int? newExcerciseID, String? newExcerciseTitle, int? newExcerciseOrder}) {
    return Excercise(
      excerciseID: newExcerciseID ?? excerciseID,
      dayID: newDayID ?? dayID,
      excerciseTitle: newExcerciseTitle ?? excerciseTitle,
      excerciseOrder: newExcerciseOrder ?? excerciseOrder,
    );
  }
}

// PLANNED SET TABLE
class PlannedSet {
  final int setID;
  final int excerciseID;
  final int numSets;
  final int setLower;
  final int? setUpper;
  final int? rpe;
  final int setOrder;


  PlannedSet({
    required this.setID, 
    required this.excerciseID, 
    required this.numSets, 
    required this.setLower, 
    this.setUpper,
    required this.setOrder,
    this.rpe,
  });

  Map<String, dynamic> toMap() {
    return {
      'set_id': setID,
      'excercise_id': excerciseID,
      'num_sets': numSets,
      'set_lower': setUpper,
      'set_upper': setUpper,
      'set_order': setOrder,
      'rpe': rpe,
    };
  }

  factory PlannedSet.fromMap(Map<String, dynamic> map) {
    return PlannedSet(
      setID: map['id'],
      excerciseID: map['excercise_id'],
      numSets: map['num_sets'],
      setUpper: map['set_upper'],
      setLower: map['set_lower'],
      setOrder: map['set_order'],
      rpe: map['rpe']
    );
  }
  @override
  String toString() {
    return 'PlannedSet{numSets: $numSets, setID: $setID, upper: $setUpper, lower: $setLower, excID: $excerciseID, setOrder: $setOrder}';
  }

  PlannedSet copyWith({int? newSetID, int? newExcerciseID, int? newNumSets, int? newSetUpper, int? newSetLower, int? newSetOrder, int? newRpe}) {
    return PlannedSet(
      setID: newSetID ?? setID,
      excerciseID: newExcerciseID ?? excerciseID,
      numSets: newNumSets ?? numSets,
      setUpper: newSetUpper ?? setUpper,
      setLower: newSetLower ?? setLower,
      setOrder: newSetOrder ?? setOrder,
      rpe: newRpe ?? rpe
    );
  }
}

// SET RECORD TABLE
class SetRecord {
  final int recordID;
  final int excerciseID;

  // Will use ISO 8601 format to store dates, yyyy-MM-ddTHH:mm:ss
  final String date;

  final int numSets;
  final int reps;
  final int weight;
  final int rpe;
  final String? historyNote;


  SetRecord({
    required this.recordID, 
    required this.excerciseID, 
    required this.date, 
    required this.numSets, 
    required this.reps,
    required this.weight,
    required this.rpe,
    this.historyNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': recordID,
      'excercise_id': excerciseID,
      'date': date,
      'num_sets': numSets,
      'reps': reps,
      'weight': weight,
      'rpe': rpe,
      'history_note': historyNote,
    };
  }

  factory SetRecord.fromMap(Map<String, dynamic> map) {
    return SetRecord(
      recordID: map['record_id'],
      excerciseID: map['excercise_id'],
      date: map['date'],
      numSets: map['num_sets'],
      reps: map['reps'],
      weight: map['weight'],
      rpe: map['rpe'],
      historyNote: map['history_note'],
    );
  }


  // Convert the string 'date' field to a DateTime object
  DateTime get dateAsDateTime {
    return DateTime.parse(date);
  }

  // Factory constructor to create a SetRecord with a DateTime object
  factory SetRecord.fromDateTime({
    required int recordID,
    required int excerciseID,

    required DateTime date,

    required int numSets,
    required int reps,
    required int weight,
    required int rpe,
    String? historyNote,
  }) {
    return SetRecord(
      recordID: recordID,
      excerciseID: excerciseID,

      date: date.toIso8601String(),
      
      numSets: numSets,
      reps: reps,
      weight: weight,
      rpe: rpe,
      historyNote: historyNote,
    );
  }

  @override
  String toString() {
    return 'HistorySet{date: $date, id: $recordID, numSets: $numSets, reps: $reps, rpe: $rpe, weight: $weight, note: $historyNote, excID: $excerciseID}';
  }
}