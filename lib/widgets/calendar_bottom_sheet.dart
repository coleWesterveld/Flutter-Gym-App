// A small glimpse of what a week of a program might look like
// for easy view at bottom while creating a program

// TODO: make tappable => take to schedule edit page
// TODO: location of days in week is not accurate - based on old system

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firstapp/providers_and_settings/program_provider.dart';  // Access Program Details
import 'package:firstapp/other_utilities/days_between.dart';

import 'package:table_calendar/table_calendar.dart';

class CalendarBottomSheet extends StatelessWidget {
  const CalendarBottomSheet({
    super.key,
    required this.today,
    required this.theme,
  });

  final DateTime today;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(8.0),
      height: 82,

      child: TableCalendar(
        headerVisible: false,
        calendarFormat: CalendarFormat.week,

        calendarBuilders: CalendarBuilders(

          // Builds a single day
          defaultBuilder: (context, day, focusedDay) {
            DateTime origin = DateTime(2024, 1, 7);
    
            // Logic to check if there is a workout on this day. this is outdated
            for (int splitDay = 0; splitDay < context.watch<Profile>().split.length; splitDay ++){
              int diff = daysBetween(origin , day) % context.watch<Profile>().splitLength;
              if (diff == (context.watch<Profile>().splitLength ~/ context.watch<Profile>().split.length) * splitDay) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(context.watch<Profile>().split[splitDay].dayColor),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              }
            }
            // No workout planned for that specific day
            return null;
          },
        ),
    
        rowHeight: 50,
        focusedDay: today, 
        firstDay: DateTime.utc(2010, 10, 16), 
        lastDay: DateTime.utc(2030, 3, 14),

        // Text Styling for Sun, Mon, Tues, etc.
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: theme.colorScheme.onSurface),
          weekendStyle: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}
