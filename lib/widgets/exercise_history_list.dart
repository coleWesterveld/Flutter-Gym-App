import 'package:firstapp/widgets/history_session_view.dart';
import 'package:flutter/material.dart';
import '../database/profile.dart';


class ExerciseHistoryList extends StatelessWidget {
  const ExerciseHistoryList({
    required this.exerciseHistory, 
    required this.theme,
    super.key,
  });

  final ThemeData theme;
  final List<List<SetRecord>> exerciseHistory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
              itemCount: exerciseHistory.length + 1,
              itemBuilder:(context, index) {
                if (index == exerciseHistory.length){
                  return const Text(
                    "End of History"
                  );
                }
      
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: HistorySessionView(
                    exerciseHistory: exerciseHistory[index], 
                    theme: theme,
                  )
                );
              }, 
            ),
    );
  }
}