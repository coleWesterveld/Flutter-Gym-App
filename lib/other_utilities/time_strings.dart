// Convert timeofday to and from strings for easy DB saving and reloading
import 'package:flutter/material.dart';

// Time conversion utilities
String timeOfDayToString(TimeOfDay time) {
  return '${time.hour}:${time.minute}';
}

TimeOfDay stringToTimeOfDay(String timeString) {
  final parts = timeString.split(':');
  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
  );
}


