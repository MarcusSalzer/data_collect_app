import 'package:data_app2/enums.dart';

extension DateOnly on DateTime {
  /// This date, with only year, month, date.
  DateTime get startOfDay => DateTime(year, month, day);

  /// Most recent monday
  DateTime get startOfweek =>
      DateTime(year, month, day).subtract(Duration(days: weekday - 1));
  DateTime get startOfMonth => DateTime(year, month);
  // DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999, 999);
}

extension CompareDT on DateTime {
  bool equalsFreq(DateTime other, TableFreq freq) {
    if (year != other.year || month != other.month) {
      return false;
    }
    switch (freq) {
      case TableFreq.day:
        return (day == other.day);
      case TableFreq.week:
        return (other.day ~/ 7 == day ~/ 7);
      case TableFreq.free:
        return (this == other);
    }
  }

  bool isToday() => startOfDay == DateTime.now().startOfDay;
}

extension Months on DateTime {
  int get monthFirstWeekday => DateTime(year, month, 1).weekday;
}

extension Capitalized on String {
  /// Capitalize first character
  String get capitalized => replaceRange(0, 1, substring(0, 1).toUpperCase());
}

extension CompareStr on String {
  bool equalsIgnoreSpace(String? other) {
    if (other is String) {
      return replaceAll(" ", "") == other.replaceAll(" ", "");
    }
    return false;
  }
}
