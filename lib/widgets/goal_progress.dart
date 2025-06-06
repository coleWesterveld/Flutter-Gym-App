// Goal circular progress indicator

import 'package:flutter/material.dart';
import 'package:firstapp/database/profile.dart';
import 'package:firstapp/widgets/circular_progress.dart';


class GoalProgress extends StatelessWidget {
  const GoalProgress({
    super.key,
    required this.goal,
    required this.size,
    required this.theme,
  });
  final Goal goal;
  final double size;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        children: [
          Center(
            child: ThickCircularProgress(
              progress: goal.progressPercentage/100, 
              completedStrokeWidth: 25.0,
              backgroundStrokeWidth: 18.0,
              completedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.outline,
              size: size - 8
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Actual',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                                
                const SizedBox(height: 5),
                
                Text(
                  '${goal.currentOneRm!.round()} lbs',
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                                
                Divider(
                  height: 5,
                  color: theme.colorScheme.outline,
                  thickness: 2.0, 
                  indent: 60.0,
                  endIndent: 60.0,
                ),
                                
                Text(
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                                
                  '${goal.targetWeight.round()} lbs',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Goal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
