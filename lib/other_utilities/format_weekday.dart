import 'package:intl/intl.dart';

// returns string from dart datetime object in format:
// "Monday, January 1st, 2024"

String _getDayWithSuffix(int day) {
  if (day >= 11 && day <= 13) {
    return '${day}th';
  }
  switch (day % 10) {
    case 1: return '${day}st';
    case 2: return '${day}nd';
    case 3: return '${day}rd';
    default: return '${day}th';
  }
}

String formatDate(DateTime date) {
  final dayOfWeek = DateFormat('EEEE').format(date);
  final month = DateFormat('MMMM').format(date);
  final dayWithSuffix = _getDayWithSuffix(date.day);
  return '$dayOfWeek, $month $dayWithSuffix, ${date.year}';
}

DateTime normalizeDay(DateTime dt) {
  return DateTime(dt.year, dt.month, dt.day);
}