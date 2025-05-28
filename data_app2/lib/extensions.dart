extension DateOnly on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  // DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999, 999);
}

extension Months on DateTime {
  int get monthFirstWeekday => DateTime(year, month, 1).weekday;
}

extension Capitalized on String {
  /// Capitalize first character
  String get capitalized => replaceRange(0, 1, substring(0, 1).toUpperCase());
}
