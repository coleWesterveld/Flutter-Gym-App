// this shows the sets logged on a given day
// provide the list of setrecords to display

import 'package:firstapp/database/profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SingleDayWorkoutView extends StatelessWidget {
  final List<SetRecord> workouts;
  final bool useMetric;
  
  const SingleDayWorkoutView({
    super.key,
    required this.workouts,
    required this.useMetric,
  });

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return const Center(
        child: Text('No workouts recorded for this day'),
      );
    }

    // Group by session first
    final sessions = _groupBySession(workouts);
    final date = workouts.first.dateAsDateTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            DateFormat('EEEE, MMMM d, y').format(date),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Sessions list
        ListView(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: sessions.entries.map((session) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildSessionCard(session.value, context),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSessionCard(List<SetRecord> sessionSets, BuildContext context) {
    // Group by exercise
    final exercises = _groupByExercise(sessionSets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Session header (program and day title)
        if (sessionSets.first.programTitle.isNotEmpty || 
            sessionSets.first.dayTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${sessionSets.first.programTitle} - ${sessionSets.first.dayTitle}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Exercises list
        ...exercises.entries.map((exercise) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise title and note
                if (exercise.value.first.historyNote?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      exercise.value.first.historyNote!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                
                Text(
                  exercise.key,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Sets list
                ...exercise.value.map((set) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${set.numSets} x ${set.reps.toStringAsFixed(set.reps.truncateToDouble() == set.reps ? 0 : 1)} reps',
                          ),
                        ),
                        Text(
                          '${useMetric ? (set.weight * 0.453592).toStringAsFixed(1) : set.weight.toStringAsFixed(1)} ${useMetric ? 'kg' : 'lbs'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'RPE ${set.rpe.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: _getRpeColor(set.rpe, context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // Helper methods (same as before)
  Map<String, List<SetRecord>> _groupBySession(List<SetRecord> sets) {
    final Map<String, List<SetRecord>> sessions = {};
    for (final set in sets) {
      if (!sessions.containsKey(set.sessionID)) {
        sessions[set.sessionID] = [];
      }
      sessions[set.sessionID]!.add(set);
    }
    return sessions;
  }

  Map<String, List<SetRecord>> _groupByExercise(List<SetRecord> sets) {
    final Map<String, List<SetRecord>> exercises = {};
    for (final set in sets) {
      final exerciseName = 'Exercise ${set.exerciseID}'; // Replace with actual name
      if (!exercises.containsKey(exerciseName)) {
        exercises[exerciseName] = [];
      }
      exercises[exerciseName]!.add(set);
    }
    return exercises;
  }

  Color _getRpeColor(double rpe, BuildContext context) {
    if (rpe >= 9.0) return Colors.red.shade700;
    if (rpe >= 8.0) return Colors.orange.shade700;
    if (rpe >= 7.0) return Colors.yellow.shade700;
    return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
  }
}