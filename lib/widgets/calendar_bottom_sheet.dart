// A small glimpse of what a week of a program might look like
// for easy view at bottom while creating a program

// TODO: make tappable => take to schedule edit page
// TODO: location of days in week is not accurate - based on old system

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firstapp/providers_and_settings/program_provider.dart';  // Access Program Details
import 'package:table_calendar/table_calendar.dart';
import 'package:firstapp/other_utilities/events.dart';
import 'package:firstapp/schedule_page/edit_schedule.dart';


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
    return GestureDetector(

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              //context.read<UiStateProvider>().customAppBarTitle = "Edit Schedule";
              return EditSchedule(
                theme: theme
              );
            }
          )
        );
      },
      child: Container(
        
        padding: const EdgeInsets.all(8.0),
        height: 82.5,

        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline,
              width: 0.5,
            ),
          ),
        ),
      
        child: TableCalendar(

          // This is kinda a strange solution but what happens is that the day absorbs the pointer from the gesture detector
          // so we just make it do the same thing! I want to detect taps BUT not absorb swipes
          onDaySelected: (_, __) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EditSchedule(
                      theme: theme
                    ),
              )
            );
          },

          focusedDay: DateTime.now(),
          headerVisible: false,
          calendarFormat: CalendarFormat.week,
      
          calendarBuilders: CalendarBuilders(
            
      
            // Builds a single day
          outsideBuilder: (context, day, focusedDay) {
            var events = getEventsForDay(
              day: day, 
              context: context,
            );
          
            //DateTime origin = DateTime(2024, 1, 7);
            
            if (events.isNotEmpty){
              return  Container(
                decoration: BoxDecoration(
                  color: today.isBefore(day) ? 
                    Color(context.watch<Profile>().split[events[0].index].dayColor): 
                    Color(context.watch<Profile>().split[events[0].index].dayColor),
                  // borderRadius: const BorderRadius.all(
                  //   Radius.circular(12.0),
                  // ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              );
            }
            
          
            return null;
          },
      
      
      
      
          defaultBuilder: (context, day, focusedDay) {
            var events = getEventsForDay(
              day: day, 
              context: context,
            );
          
            //DateTime origin = DateTime(2024, 1, 7);
            
            if (events.isNotEmpty){
              return  Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: today.isBefore(day) ? 
                      Color(context.watch<Profile>().split[events[0].index].dayColor): 
                      Color(context.watch<Profile>().split[events[0].index].dayColor),
                    // borderRadius: const BorderRadius.all(
                    //   Radius.circular(12.0),
                    // ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(color: theme.colorScheme.onPrimary),
                    ),
                  ),
                ),
              );
            }
            
            return null;
          },
      
          ),
          rowHeight: 50,
          firstDay: DateTime.utc(2010, 10, 16), 
          lastDay: DateTime.utc(2030, 3, 14),
          calendarStyle: CalendarStyle(
          
            todayDecoration: _buildToday(today, context),
            //markerDecoration: const BoxDecoration(),
            defaultDecoration: const BoxDecoration(
              //color: Colors.white,
              //borderRadius: BorderRadius.circular(14),
              shape: BoxShape.circle,
            ),
            
            // the days default to circle shape, and this throws errors on animating selection (even after chaning default)
            // idk a better way to do this, but this works, even if its maybe not elegant
            rangeEndDecoration: const BoxDecoration(
              //color: Colors.white,
              //borderRadius: BorderRadius.circular(14),
              shape: BoxShape.circle,
            ),
            weekendDecoration: const BoxDecoration(
              //color: Colors.white,
              //borderRadius: BorderRadius.circular(14),
              shape: BoxShape.circle,
            ),
            outsideDecoration: const BoxDecoration(
              //color: Colors.white,
              //borderRadius: BorderRadius.circular(14),
              shape: BoxShape.circle,
            ),
      
            selectedTextStyle: TextStyle(
              color: theme.colorScheme.onPrimary, 
              fontWeight: FontWeight.bold,
            ),
      
            weekendTextStyle: TextStyle(color: theme.colorScheme.onSurface)
      
          ),
      
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: theme.colorScheme.onSurface),
            weekendStyle: TextStyle(color: theme.colorScheme.onSurface),
          ),
      
        ),
      ),
    );
  }

  BoxDecoration _buildToday(DateTime day, BuildContext context) {
    var events = getEventsForDay(
      day: day, 
      context: context,
    );
    return BoxDecoration(
      border: Border.all(width: 3, color: theme.colorScheme.onSurface),
      //borderRadius: BorderRadius.circular(12),
      shape: BoxShape.circle,
      color: (events.isEmpty) 
      ? theme.colorScheme.surface
      : Color(context.watch<Profile>().split[events[0].index].dayColor)
    );
  }
}
