import 'package:flutter/material.dart';
// at some point, this should be merged with Profile class in user.dart
// for now, I am setting up relational local database to store user data, 
// and so I will start fresh 
// to make it easier to follow the tutorial.
// https://www.youtube.com/watch?v=t39VV2XyqR0&t=128s
// ^ tutorial series from SmartHerd on YT, used to create this

// Also with help of the one and only ChatGPT

// For now, for saving the set record I will match sets by sessionID and the history note will be copied for every set, or maybe just the first one
// at some point, should probably make  exercises -> many setClusterHistory -> many Individual sets
// to group by date, session, and have one note to define everything

class UserSettings {
  final int? id;
  final int? currentProgramId;
  final String themeMode; // 'light', 'dark', or 'system'
  final DateTime? programStartDate;
  final int programDurationDays;
  final bool isMidWorkout;
  final bool useMetric; // lbs default, can be Kgs
  final int? lastWorkoutId;
  final DateTime? lastWorkoutTimestamp;
  final int restTimerSeconds;
  final bool enableSound;
  final bool enableHaptics;
  final bool autoRestTimer;
  final bool colourBlindMode;

  UserSettings({
    this.id,
    this.currentProgramId,
    this.themeMode = 'system',
    this.programStartDate,
    this.programDurationDays = 28,
    this.isMidWorkout = false,
    this.useMetric = false,
    this.lastWorkoutId,
    this.lastWorkoutTimestamp,
    this.restTimerSeconds = 90,
    this.enableSound = true,
    this.enableHaptics = true,
    this.autoRestTimer = false,
    this.colourBlindMode = false,
  });

  // convert to map for database operations, and remove null vals
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'current_program_id': currentProgramId,
      'theme_mode': themeMode,
      'program_start_date': programStartDate?.toIso8601String(),
      'program_duration_days': programDurationDays,
      'is_mid_workout': isMidWorkout ? 1 : 0,
      'use_metric': useMetric ? 1 : 0,
      'last_workout_id': lastWorkoutId,
      'last_workout_timestamp': lastWorkoutTimestamp?.toIso8601String(),
      'rest_timer_seconds': restTimerSeconds,
      'enable_sound': enableSound ? 1 : 0,
      'enable_haptics': enableHaptics ? 1 : 0,
      'auto_rest_timer': autoRestTimer ? 1 : 0,
      'colour_blind_mode': colourBlindMode ? 1 : 0
    };
    
    // Remove null values
    map.removeWhere((key, value) => value == null);
    
    return map;
  }

  // Create from database map
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'] as int?,
      currentProgramId: map['current_program_id'] as int?,
      themeMode: map['theme_mode'] as String? ?? 'system',
      programStartDate: map['program_start_date'] != null 
          ? DateTime.parse(map['program_start_date'] as String) 
          : null,
      programDurationDays: map['program_duration_days'] as int? ?? 28,
      isMidWorkout: (map['is_mid_workout'] as int? ?? 0) == 1,
      useMetric: (map['use_metric'] as int? ?? 0) == 1,
      lastWorkoutId: map['last_workout_id'] as int?,
      lastWorkoutTimestamp: map['last_workout_timestamp'] != null 
          ? DateTime.parse(map['last_workout_timestamp'] as String) 
          : null,
      restTimerSeconds: map['rest_timer_seconds'] as int? ?? 90,
      enableSound: (map['enable_sound'] as int? ?? 1) == 1,
      enableHaptics: (map['enable_haptics'] as int? ?? 1) == 1,
      autoRestTimer: (map['auto_rest_timer'] as int? ?? 0) == 1,
      colourBlindMode: (map['colourBlindMode'] as int? ?? 0) == 1
    );
  }

  UserSettings copyWith({
    int? id,
    int? currentProgramId,
    String? themeMode,
    DateTime? programStartDate,
    int? programDurationDays,
    bool? isMidWorkout,
    bool? useMetric,
    int? lastWorkoutId,
    DateTime? lastWorkoutTimestamp,
    int? restTimerSeconds,
    bool? enableSound,
    bool? enableHaptics,
    bool? autoRestTimer,
    bool? colourBlindMode,
  }) {
    return UserSettings(
      id: id ?? this.id,
      currentProgramId: currentProgramId ?? this.currentProgramId,
      themeMode: themeMode ?? this.themeMode,
      programStartDate: programStartDate ?? this.programStartDate,
      programDurationDays: programDurationDays ?? this.programDurationDays,
      isMidWorkout: isMidWorkout ?? this.isMidWorkout,
      useMetric: useMetric ?? this.useMetric,
      lastWorkoutId: lastWorkoutId ?? this.lastWorkoutId,
      lastWorkoutTimestamp: lastWorkoutTimestamp ?? this.lastWorkoutTimestamp,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
      enableSound: enableSound ?? this.enableSound,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      autoRestTimer: autoRestTimer ?? this.autoRestTimer,
      colourBlindMode: colourBlindMode ?? this.colourBlindMode,
    );
  }

  @override
  String toString() {
    return 'UserSettings('
        'id: $id, '
        'currentProgramId: $currentProgramId, '
        'themeMode: $themeMode, '
        'programStartDate: $programStartDate, '
        'programDurationDays: $programDurationDays, '
        'isMidWorkout: $isMidWorkout, '
        'useMetric: $useMetric, '
        'lastWorkoutId: $lastWorkoutId, '
        'lastWorkoutTimestamp: $lastWorkoutTimestamp, '
        'restTimerSeconds: $restTimerSeconds, '
        'enableSound: $enableSound, '
        'enableHaptics: $enableHaptics, '
        'autoRestTimer: $autoRestTimer'
        'colourBlindMode: $colourBlindMode'
        ')';
  }
}

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
      programID: map['id'],
      programTitle: map['program_title'],
    );
  }

  Program copyWith({int? newID, String? newTitle}) {
    return Program(
      programID: newID ?? programID,
      programTitle: newTitle ?? programTitle,
    );
  }

  @override
  String toString() {
    return 'Program{title: $programTitle, id: $programID}';
  }
}

// DAY TABLE
// (one day -> many exercises)
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

// exercise_instances TABLE
// (one exercise -> many planned sets, many set records)
class Exercise {
  final int id;
  final int exerciseID;
  final int dayID;
  final String exerciseTitle;
  final int exerciseOrder;


  Exercise({
    required this.id,
    required this.exerciseID, 
    required this.dayID, 
    required this.exerciseTitle, 
    required this.exerciseOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_id': exerciseID,
      'day_id': dayID,
      'exercise_title': exerciseTitle,
      'exercise_order': exerciseOrder,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      exerciseID: map['exercise_id'],
      dayID: map['day_id'],
      exerciseTitle: map['exercise_title'],
      exerciseOrder: map['exercise_order']
    );
  }
  @override
  String toString() {
    return 'exercise{title: $exerciseTitle, id: $exerciseID, dayID: $dayID';
  }

  Exercise copyWith({int? newDayID, int? newexerciseID, String? newexerciseTitle, int? newexerciseOrder, int? newID}) {
    return Exercise(
      id: newID ?? id,
      exerciseID: newexerciseID ?? exerciseID,
      dayID: newDayID ?? dayID,
      exerciseTitle: newexerciseTitle ?? exerciseTitle,
      exerciseOrder: newexerciseOrder ?? exerciseOrder,
    );
  }
}

// PLANNED SET TABLE
class PlannedSet {
  final int setID;
  final int exerciseID;
  final int numSets;
  final int setLower;
  final int? setUpper;
  final int? rpe;
  final int setOrder;
  List<bool> hasBeenLogged;

  PlannedSet({
    required this.setID, 
    required this.exerciseID, 
    required this.numSets, 
    required this.setLower, 
    this.setUpper,
    required this.setOrder,
    this.rpe,
    List<bool>? hasBeenLogged,
  }) : hasBeenLogged = hasBeenLogged ?? List.filled(numSets, false);

  Map<String, dynamic> toMap() {
    return {
      'set_id': setID,
      'exercise_id': exerciseID,
      'num_sets': numSets,
      'set_lower': setLower,
      'set_upper': setUpper,
      'set_order': setOrder,
      'rpe': rpe,
    };
  }

  factory PlannedSet.fromMap(Map<String, dynamic> map) {
    return PlannedSet(
      setID: map['id'],
      exerciseID: map['exercise_id'],
      numSets: map['num_sets'],
      setUpper: map['set_upper'],
      setLower: map['set_lower'],
      setOrder: map['set_order'],
      rpe: map['rpe'],
      // Will be initialized through main constructor
    );
  }

  @override
  String toString() {
    return 'PlannedSet{numSets: $numSets, setID: $setID, upper: $setUpper, lower: $setLower, excID: $exerciseID, setOrder: $setOrder}';
  }

  PlannedSet copyWith({
    int? newSetID, 
    int? newexerciseID, 
    int? newNumSets, 
    int? newSetUpper, 
    int? newSetLower, 
    int? newSetOrder, 
    int? newRpe,
    List<bool>? newHasBeenLogged,
  }) {
    return PlannedSet(
      setID: newSetID ?? setID,
      exerciseID: newexerciseID ?? exerciseID,
      numSets: newNumSets ?? numSets,
      setUpper: newSetUpper ?? setUpper,
      setLower: newSetLower ?? setLower,
      setOrder: newSetOrder ?? setOrder,
      rpe: newRpe ?? rpe,
      hasBeenLogged: newHasBeenLogged ?? List.from(hasBeenLogged),
    );
  }
}

// SET RECORD TABLE
class SetRecord {
  final int? recordID;
  final int exerciseID;
  final String sessionID;

  // Will use ISO 8601 format to store dates, yyyy-MM-ddTHH:mm:ss
  final String date;

  final int numSets;
  final int reps;
  final int weight;
  final int rpe;
  final String? historyNote;

  SetRecord({
    required this.sessionID,
    this.recordID, 
    required this.exerciseID, 
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
      'exercise_id': exerciseID,
      'date': date,
      'num_sets': numSets,
      'reps': reps,
      'weight': weight,
      'rpe': rpe,
      'history_note': historyNote ?? '',
      'session_id' : sessionID,
    };
  }

  factory SetRecord.fromMap(Map<String, dynamic> map) {
    return SetRecord(
      recordID: map['record_id'],
      exerciseID: map['exercise_id'],
      date: map['date'],
      numSets: map['num_sets'],
      reps: map['reps'],
      weight: map['weight'],
      rpe: map['rpe'],
      historyNote: map['history_note'],
      sessionID: map['session_id'],
    );
  }


  // Convert the string 'date' field to a DateTime object
  DateTime get dateAsDateTime {
    return DateTime.parse(date);
  }

  // Factory constructor to create a SetRecord with a DateTime object
  factory SetRecord.fromDateTime({
    int? recordID,
    required int exerciseID,

    required DateTime date,

    required int numSets,
    required int reps,
    required int weight,
    required int rpe,
    required String sessionID,
    String? historyNote,
  }) {
    return SetRecord(
      recordID: recordID,
      exerciseID: exerciseID,
      sessionID: sessionID,

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
    return 'HistorySet{date: $date, id: $recordID, numSets: $numSets, reps: $reps, rpe: $rpe, weight: $weight, note: $historyNote, excID: $exerciseID}';
  }
}

class Goal {
  final int? id; // Nullable for new goals not yet saved
  final int exerciseId;
  final String exerciseTitle;
  final int targetWeight;
  final int? currentOneRm; // Nullable (calculated when fetched)

  Goal({
    this.id,
    required this.exerciseId,
    required this.exerciseTitle,
    required this.targetWeight,
    this.currentOneRm,
  });

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'goal_weight': targetWeight,
      // Note: exerciseTitle and currentOneRm aren't stored in DB
    };
  }

  // Create from database map
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      exerciseId: map['exercise_id'],
      exerciseTitle: map['exercise_title'] ?? '',
      targetWeight: map['goal_weight'],
      currentOneRm: map['current_one_rm'],
    );
  }

  // Progress percentage (0-100)
  double get progressPercentage {
    if (currentOneRm == null || currentOneRm == 0) return 0;
    return (currentOneRm! / targetWeight) * 100;
  }

  Goal copyWith({
    int? id,
    int? exerciseId,
    String? exerciseTitle,
    int? targetWeight,
    int? currentOneRm,
  }) {
    return Goal(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseTitle: exerciseTitle ?? this.exerciseTitle,
      targetWeight: targetWeight ?? this.targetWeight,
      currentOneRm: currentOneRm ?? this.currentOneRm,
    );
  }

  @override
  String toString() {
    return 'Goal(id: $id, exercise: $exerciseTitle, target: $targetWeight, current: $currentOneRm)';
  }
}
