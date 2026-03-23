import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/view_models/duration_summary_display_vm.dart';
import 'package:flutter/material.dart';

/// Handle data for showing stats for a month
class MonthVm extends DurationSummaryDisplayVm {
  @override
  LocalTimeRangeQuery get rangeQuery => LocalTimeRangeQuery(
    ref: _current,
    dayOffset: dayStart,
    unit: GroupFreq.month,
    overlapMode: OverlapMode.fullyInside,
  );

  DateTime _current;

  List<DateTime> _days;

  MonthVm(this._current, super.dayStart, super.db, super.typeManager, super.colorSpread, super._summaryMode)
    : _days = _makeDayGrid(_current);

  DateTime get currentMonth => _current;
  List<DateTime> get days => _days;

  /// Make a list of days. It will have length (35, 42 or (very rarely) 28)
  static List<DateTime> _makeDayGrid(DateTime ref) {
    final firstDay = ref.startOfMonth;
    final offset = ref.monthFirstWeekday; // 0–6
    final daysInMonth = DateUtils.getDaysInMonth(firstDay.year, firstDay.month);

    final totalCells = offset + daysInMonth;
    final weeks = (totalCells / 7).ceil();
    final cellCount = weeks * 7;

    return List.generate(cellCount, (i) => DateUtils.addDaysToDate(firstDay, i - offset + 1));
  }

  /// Move to a new month and reload data
  Future<void> stepMonth(int offset) async {
    _current = DateUtils.addMonthsToMonthDate(currentMonth, offset);
    _days = _makeDayGrid(_current);
    await load();
    notifyListeners();
  }

  /// Move to a new month and reload data
  Future<void> stepTo(DateTime dt) async {
    _current = dt.startOfMonth;
    _days = _makeDayGrid(_current);
    await load();
    notifyListeners();
  }

  List<int>? eventsPerDay() {
    final events = eventList;
    if (events == null) return null;

    final counts = List.filled(_days.length, 0);
    for (var e in events) {
      final startLocal = e.start?.asLocal;
      if (startLocal == null) continue;

      final idx = startLocal.day;
      counts[idx]++;
    }
    return counts;
  }

  bool isInMonth(DateTime day) => day.month == _current.month;
}
