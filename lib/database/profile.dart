
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
      programID: map['programID'],
      programTitle: map['programTitle'],
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

  Day({required this.dayID, required this.dayTitle, required this.programID, required this.dayColor});

  Map<String, dynamic> toMap() {
    return {
      'dayID': dayID,
      'dayTitle': dayTitle,
      'programID': programID,
      'dayColor': dayColor,
    };
  }

  factory Day.fromMap(Map<String, dynamic> map) {
    return Day(
      dayColor: map['dayColor'],
      dayID: map['dayID'],
      dayTitle: map['dayTitle'],
      programID: map['programID'],
    );
  }

  @override
  String toString() {
    return 'Day{title: $dayTitle, id: $dayID, prgmID: $programID}';
  }


  Day copyWith({int? newDayColor, int? newDayID, String? newDayTitle, int? newProgramID}) {
    return Day(
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


  Excercise({
    required this.excerciseID, 
    required this.dayID, 
    required this.excerciseTitle, 
    this.persistentNote
  });

  Map<String, dynamic> toMap() {
    return {
      'id': excerciseID,
      'dayID': dayID,
      'excerciseTitle': excerciseTitle,
      'persistentNote': persistentNote,
    };
  }

  factory Excercise.fromMap(Map<String, dynamic> map) {
    return Excercise(
      excerciseID: map['id'],
      dayID: map['dayID'],
      excerciseTitle: map['excerciseTitle'],
      persistentNote: map['persistentNote'],
    );
  }
  @override
  String toString() {
    return 'Excercise{title: $excerciseTitle, id: $excerciseID, dayID: $dayID, persistNote: $persistentNote}';
  }
}

// PLANNED SET TABLE
class PlannedSet {
  final int setID;
  final int excerciseID;
  final int numSets;
  final int setLower;
  final int? setUpper;


  PlannedSet({
    required this.setID, 
    required this.excerciseID, 
    required this.numSets, 
    required this.setLower, 
    this.setUpper
  });

  Map<String, dynamic> toMap() {
    return {
      'setID': setID,
      'excerciseID': excerciseID,
      'numSets': numSets,
      'setLower': setUpper,
      'setUpper': setUpper,
    };
  }

  factory PlannedSet.fromMap(Map<String, dynamic> map) {
    return PlannedSet(
      setID: map['setID'],
      excerciseID: map['excerciseID'],
      numSets: map['numSets'],
      setUpper: map['setUpper'],
      setLower: map['setLower'],
    );
  }
  @override
  String toString() {
    return 'PlannedSet{numSets: $numSets, setID: $setID, upper: $setUpper, lower: $setLower, excID: $excerciseID}';
  }
}

// SET RECORD TABLE
class SetRecord {
  final int recordID;
  final int excerciseID;
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
      'recordID': recordID,
      'excerciseID': excerciseID,
      'date': date,
      'numSets': numSets,
      'reps': reps,
      'weight': weight,
      'rpe': rpe,
      'historyNote': historyNote,
    };
  }

  factory SetRecord.fromMap(Map<String, dynamic> map) {
    return SetRecord(
      recordID: map['recordID'],
      excerciseID: map['excerciseID'],
      date: map['date'],
      numSets: map['numSets'],
      reps: map['reps'],
      weight: map['weight'],
      rpe: map['rpe'],
      historyNote: map['historyNote'],
    );
  }
  @override
  String toString() {
    return 'HistorySet{date: $date, id: $recordID, numSets: $numSets, reps: $reps, rpe: $rpe, weight: $weight, note: $historyNote, excID: $excerciseID}';
  }
}