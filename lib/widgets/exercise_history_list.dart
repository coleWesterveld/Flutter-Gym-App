import 'package:firstapp/widgets/history_session_view.dart';
import 'package:flutter/material.dart';
import '../database/profile.dart';


class ExerciseHistoryList extends StatelessWidget {
  const ExerciseHistoryList({
    required this.exerciseHistory, 
    required this.theme,
    required this.isLoadingMore,
    required this.hasMoreData,

    super.key,
  });

  final ThemeData theme;
  final List<List<SetRecord>> exerciseHistory;
  final bool isLoadingMore;
  final bool hasMoreData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
          itemCount: exerciseHistory.length + 1,
          itemBuilder:(context, index) {
            if (index == exerciseHistory.length) {
            // If currently loading more data, show the loading indicator
            if (isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (!hasMoreData) {
              // If not loading and there is no more data, show the "End of History" message
              return const Padding(
                 padding: EdgeInsets.symmetric(vertical: 20.0),
                 child: Center(
                   child: Text(
                     "End of History",
                     style: TextStyle(fontStyle: FontStyle.italic),
                   ),
                 ),
               );
            } else {
               // This case should ideally not be reached if state management is correct,
               // but as a fallback, maybe show nothing or the loading indicator if still expecting more.
               // Let's show nothing if not loading but still theoretically have data (unlikely state)
               return const SizedBox.shrink();
            }
          }

  
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: HistorySessionView(
              color: theme.colorScheme.surfaceContainerHighest,
              exerciseHistory: exerciseHistory[index], 
              theme: theme,
            )
          );
        }, 
      ),
    );
  }
}