// Some helpers to load events (workouts) for the calendar

import 'package:firstapp/providers_and_settings/program_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firstapp/other_utilities/days_between.dart';


class Event{
  final String title;
  final int index;
  Event(this.title, this.index);
}

// Given a specific date and program start day, this function will find the workout, if any, for a specific day
// from the split in the program provider
List<Event> getEventsForDay ({required DateTime day, required BuildContext context, DateTime? startDay}){
  // startday should be provider origin if not provided
  startDay = context.read<Profile>().origin;

  for (var splitDay = 0; splitDay < context.read<Profile>().split.length; splitDay ++){
    // if days between origin and day is equal to dayorder

    if (daysBetween(startDay , day) % context.read<Profile>().splitLength == context.read<Profile>().split[splitDay].dayOrder) {
      return [Event(context.read<Profile>().split[splitDay].dayTitle, splitDay)];
    }
  }
  return [];
}