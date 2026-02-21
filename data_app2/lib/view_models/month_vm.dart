import 'dart:collection';

import 'package:data_app2/data/evt.dart';
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

  DateTime _current = DateTime.now().startOfMonth;

  List<DateTime> _days = [];
  List<EvtRec>? _events;

  MonthVm(super.dayStart, super.db, super.typeManager, super.colorSpread);

  DateTime get currentMonth => _current;
  List<DateTime> get days => _days;

  UnmodifiableListView<EvtRec>? get events {
    final evts = _events;
    if (evts == null) return null;
    return UnmodifiableListView(evts);
  }

  /// load events for current month
  @override
  Future<void> load() async {
    final evts = (await db.evts.filteredLocalTime(range: rangeQuery.toDbRange())).toList();

    // Compute summary from events
    refreshSummary(evts);

    // remember events
    _events = evts;
    notifyListeners();
  }

  /// Make 6x7 grid of days
  void _makeDayGrid() {
    final offset = _current.monthFirstWeekday;

    _days = List.generate(42, (i) => DateUtils.addDaysToDate(_current.startOfMonth, i - offset + 1));
  }

  /// Move to a new month and reload data
  void stepMonth(int offset) {
    _current = DateUtils.addMonthsToMonthDate(currentMonth, offset);
    _makeDayGrid();
    notifyListeners();
    load();
  }

  List<int>? eventsPerDay() {
    final evts = _events;
    if (evts == null) return null;

    final counts = List.filled(_days.length, 0);
    for (var e in evts) {
      final startLocal = e.start?.asUtcWithLocalValue;
      if (startLocal == null) continue;

      final idx = startLocal.day;
      counts[idx]++;
    }
    return counts;
  }

  bool isInMonth(DateTime day) => day.month == _current.month;
}
