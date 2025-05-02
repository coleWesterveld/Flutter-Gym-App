// For defining timespan when viewing history
enum Timespan { allTime, oneMonth, sixMonths, oneYear }

extension TimespanExtension on Timespan {
  String get displayName {
    switch (this) {
      case Timespan.allTime:
        return 'All Time';
      case Timespan.oneMonth:
        return 'Last 30 Days';
      case Timespan.sixMonths:
        return '6 Months';
      case Timespan.oneYear:
        return '1 Year';
    }
  }
}

  DateTime getStartDateForTimespan(Timespan timespan) {
    final now = DateTime.now();
    switch (timespan) {
      case Timespan.oneMonth:
        return now.subtract(const Duration(days: 30));
      case Timespan.sixMonths:
        return DateTime(now.year, now.month - 6, now.day);
      case Timespan.oneYear:
        return DateTime(now.year - 1, now.month, now.day);
      case Timespan.allTime:
        // Return a very old date to include everything
        return DateTime(1977);
    }
  }