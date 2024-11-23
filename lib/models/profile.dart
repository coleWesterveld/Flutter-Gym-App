
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
  final int? programID;
  final String programTitle;

  Program({this.programID, required this.programTitle});

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
}

// DAY TABLE
// (one day -> many excercises)
class Day {
  final int? dayID;
  final String dayTitle;
  final int programID;

  Day({this.dayID, required this.dayTitle, required this.programID});

  Map<String, dynamic> toMap() {
    return {
      'dayID': dayID,
      'dayTitle': dayTitle,
      'programID': programID,
    };
  }

  factory Day.fromMap(Map<String, dynamic> map) {
    return Day(
      dayID: map['dayID'],
      dayTitle: map['dayTitle'],
      programID: map['programID'],
    );
  }
}

// EXCERCISE TABLE
// (one excercise -> many planned sets, many set records)
class Excercise {
  final int? excerciseID;
  final int dayID;
  final String excerciseTitle;
  final String? persistentNote;


  Excercise({
    this.excerciseID, 
    required this.dayID, 
    required this.excerciseTitle, 
    this.persistentNote
  });

  Map<String, dynamic> toMap() {
    return {
      'excerciseID': excerciseID,
      'dayID': dayID,
      'excerciseTitle': excerciseTitle,
      'persistentNote': persistentNote,
    };
  }

  factory Excercise.fromMap(Map<String, dynamic> map) {
    return Excercise(
      excerciseID: map['excerciseID'],
      dayID: map['dayID'],
      excerciseTitle: map['excerciseTitle'],
      persistentNote: map['persistentNote'],
    );
  }
}

// PLANNED SET TABLE
class PlannedSet {
  final int? setID;
  final int excerciseID;
  final int numSets;
  final int setLower;
  final int? setUpper;


  PlannedSet({
    this.setID, 
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
}

// SET RECORD TABLE
class SetRecord {
  final int? recordID;
  final int excerciseID;
  final String date;
  final int numSets;
  final int reps;
  final int weight;
  final int rpe;
  final String? historyNote;


  SetRecord({
    this.recordID, 
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
}