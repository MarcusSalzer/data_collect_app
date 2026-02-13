import 'package:data_app2/util/enums.dart';
import 'package:logging/logging.dart' show Level;

extension DateOnly on DateTime {
  /// This date, with only year, month, date.
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  DateTime get startOfDayUtc {
    return DateTime.utc(year, month, day);
  }

  /// Most recent monday
  DateTime get startOfweek {
    return DateTime(year, month, day).subtract(Duration(days: weekday - 1));
  }

  DateTime get startOfweekUtc {
    return DateTime.utc(year, month, day).subtract(Duration(days: weekday - 1));
  }

  /// Most recent first day of month
  DateTime get startOfMonth {
    return DateTime(year, month);
  }

  DateTime get startOfMonthUtc {
    return DateTime.utc(year, month);
  }

  /// Start of next month
  DateTime get endOfMonth {
    return DateTime(year, month + 1);
  }

  DateTime get endOfMonthUtc {
    return DateTime.utc(year, month + 1);
  }
}

extension Groups on DateTime {
  /// Get the most recent start of a period
  DateTime startOfPeriod(GroupFreq f) {
    return switch (f) {
      GroupFreq.day => startOfDay,
      GroupFreq.week => startOfweek,
      GroupFreq.month => startOfMonth,
    };
  }

  DateTime startOfPeriodUtc(GroupFreq f) {
    return switch (f) {
      GroupFreq.day => startOfDayUtc,
      GroupFreq.week => startOfweekUtc,
      GroupFreq.month => startOfMonthUtc,
    };
  }
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

extension Range on GroupFreq {
  /// Generate a range of values with this period (inclusive)
  Iterable<DateTime> genRange(DateTime start, DateTime stop) sync* {
    var p = start.startOfPeriod(this);
    while (!p.isAfter(stop)) {
      yield p;
      // step according to this frequency
      switch (this) {
        case GroupFreq.day:
          p = p.copyWith(day: p.day + 1);
        case GroupFreq.week:
          p = p.copyWith(day: p.day + 7);
        case GroupFreq.month:
          p = p.copyWith(month: p.month + 1);
      }
    }
  }
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

/// For converting "user/db facing" enum to logging Level
extension ToLogging on LogLevel {
  Level toLogging() {
    switch (this) {
      case LogLevel.off:
        // The logging package has no OFF constant.
        // But level > SHOUT disables everything.
        return Level('OFF', Level.SHOUT.value + 1);
      case LogLevel.error:
        return Level.SEVERE;
      case LogLevel.warning:
        return Level.WARNING;
      case LogLevel.info:
        return Level.INFO;
      case LogLevel.debug:
        return Level.FINE;
    }
  }
}

// /// For converting Logging level "user/db facing" enum
// extension FromLogging on Level {
//   LogLevel toPrefs() {
//     if (value <= Level.SEVERE.value) {
//       return LogLevel.error;
//     } else if (value <= Level.WARNING.value) {
//       return LogLevel.warning;
//     } else if (value <= Level.INFO.value) {
//       return LogLevel.info;
//     } else if (value <= Level.FINE.value) {
//       return LogLevel.debug;
//     } else {
//       return LogLevel.off;
//     }
//   }
// }
