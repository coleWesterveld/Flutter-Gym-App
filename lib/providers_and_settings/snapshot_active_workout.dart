/* 
I want the workout to continue seamlessly if the user closes and reopens the app during a workout. 
I will just use shared_preferences and json for this -- I know I already have the SQLite DB, 
but adding a separate table for this relatively short-term buffer seems overkill and unnessecary
*/

import 'dart:convert'; // For jsonEncode/jsonDecode
import 'package:firstapp/providers_and_settings/active_workout_provider.dart';

// json encode/decode methods to save and load an active workout 
/// to be combined with [ActiveWorkoutProvider]
class ActiveWorkoutSnapshot {
  final String sessionID;
  final int activeDayIndex; // Index within the current program's days
  // You might also need to save the ID of the Program this day belongs to
  // final String activeProgramID;
  final List<int> nextSet; // e.g., [exerciseIndex, setIndex, subSetIndex]

  // Stopwatch state
  final DateTime startWorkoutTime;
  final DateTime startRestTime;
  final bool stopwatchIsRunning;

  // TEC values: key format e.g., "e0_s1_ss2_reps" or "e0_notes"
  final Map<String, String> tecValues;

  // Expansion states for exercises (optional, but good for UX)
  final List<bool>? exerciseExpansionStates;

  final List<List<List<int?>>>? loggedRecordIDs;

  ActiveWorkoutSnapshot({
    required this.sessionID,
    required this.activeDayIndex,
    // required this.activeProgramID,
    required this.nextSet,
    required this.startWorkoutTime,
    required this.stopwatchIsRunning,
    required this.startRestTime,
    required this.tecValues,
    this.exerciseExpansionStates,
    this.loggedRecordIDs,
  });

  factory ActiveWorkoutSnapshot.fromJson(Map<String, dynamic> json) {
    List<List<List<int?>>>? parsedLoggedRecordIDs;
    if (json['loggedRecordIDs'] != null) {
      // Safely parse the nested list structure
      try {
        parsedLoggedRecordIDs = (json['loggedRecordIDs'] as List<dynamic>).map((exerciseList) {
          return (exerciseList as List<dynamic>).map((setGroupList) {
            return (setGroupList as List<dynamic>).map((id) => id as int?).toList();
          }).toList();
        }).toList();
      } catch (e) {
        print("Error parsing loggedRecordIDs from JSON: $e. Setting to null.");
        parsedLoggedRecordIDs = null;
      }
    }

    return ActiveWorkoutSnapshot(
      sessionID: json['sessionID'] as String,
      activeDayIndex: json['activeDayIndex'] as int,
      nextSet: List<int>.from(json['nextSet'] as List),
      startWorkoutTime: DateTime.tryParse(json['startWorkoutTime'] as String) ?? DateTime.now(),
      stopwatchIsRunning: json['stopwatchIsRunning'] as bool,
      startRestTime: DateTime.tryParse(json['startRestTime'] as String) ?? DateTime.now(),
      tecValues: Map<String, String>.from(json['tecValues'] as Map),
      exerciseExpansionStates: json['exerciseExpansionStates'] != null
          ? List<bool>.from(json['exerciseExpansionStates'] as List)
          : null,
      loggedRecordIDs: parsedLoggedRecordIDs, // Assign parsed value
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionID': sessionID,
    'activeDayIndex': activeDayIndex,
    'nextSet': nextSet,
    'startWorkoutTime': startWorkoutTime.toIso8601String(),
    'stopwatchIsRunning': stopwatchIsRunning,
    'startRestTime': startRestTime.toIso8601String(),
    'tecValues': tecValues,
    'exerciseExpansionStates': exerciseExpansionStates,
    'loggedRecordIDs': loggedRecordIDs, // Add to JSON (jsonEncode handles List<List<List<int?>>> fine)
  };
}