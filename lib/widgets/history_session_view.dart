// Given a list of setrecords from the same session, it will display them together
// This is to view all sets of one exercise for a session
// A list of these pair well with dbHelper.getPreviousSessionSets()

import 'package:firstapp/other_utilities/format_weekday.dart';
import 'package:firstapp/other_utilities/unit_conversions.dart';
import 'package:firstapp/providers_and_settings/settings_provider.dart';
import 'package:flutter/material.dart';
import '../other_utilities/lightness.dart';
import '../database/profile.dart';
import 'package:provider/provider.dart';
import 'package:firstapp/other_utilities/format_reps.dart';

class HistorySessionView extends StatelessWidget {
  const HistorySessionView({
    super.key,
    required this.exerciseHistory,
    required this.theme,
  });

  final List<SetRecord> exerciseHistory;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsModel>();
    return Container(
      
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12)
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "${formatDate(exerciseHistory[0].dateAsDateTime)}: ",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                )
              )
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exerciseHistory.length,
              itemBuilder: (context, historyIndex) {
                String formattedWeight = '';
                if (settings.useMetric){
                  formattedWeight = "${formatWeight(lbToKg(pounds: exerciseHistory[historyIndex].weight))} kg";
                } else{
                  formattedWeight = "${formatWeight(exerciseHistory[historyIndex].weight)} lbs";
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8,
                  ),
                  child: Text(
                    "${exerciseHistory[historyIndex].numSets} sets x ${formatReps(exerciseHistory[historyIndex].reps)} reps @ $formattedWeight (RPE: ${exerciseHistory[historyIndex].rpe})",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w700
                    ),
                  ),
                );
              },
            ),

            if (exerciseHistory[0].historyNote != null && exerciseHistory[0].historyNote!.isNotEmpty) 
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Notes: ${exerciseHistory[0].historyNote}"
                ),
              ),
          ],
        ),
      ),
    );
  }
}
