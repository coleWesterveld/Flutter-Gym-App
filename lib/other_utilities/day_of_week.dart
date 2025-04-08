
/*
 This function will return Datetime of certain day of current week
 eg. monday of this week, or thursday of this week
 takes int 1-7, 1 is monday, 7 is sunday
*/
DateTime getDayOfCurrentWeek(int desiredWeekday) {
  assert(desiredWeekday >= 1 && desiredWeekday <= 7, 
      "desiredWeekday must be an integer between 1 (Monday) and 7 (Sunday)");

  DateTime now = DateTime.now(); // Current date and time
  int currentWeekday = now.weekday; // 1 (Monday) to 7 (Sunday)
  
  // Calculate the desired day's date
  DateTime targetDate = now.add(Duration(days: desiredWeekday - currentWeekday));
  return DateTime(targetDate.year, targetDate.month, targetDate.day); // Return at midnight
}