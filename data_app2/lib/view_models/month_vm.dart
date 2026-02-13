import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/today_summary_data.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/event_stats_compute.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Handle data for showing stats for a month
class MonthVm extends ChangeNotifier {
  final AppState _app;
  DateTime _current = DateTime.now().startOfMonth;
  SummaryDataList? summary;

  List<DateTime> _days = [];
  List<EvtRec> _events = [];
  late Future<void> loadFuture;

  MonthVm(this._app) {
    loadFuture = _loadEvents();
    _makeDayGrid();
  }

  DateTime get currentMonth => _current;
  List<DateTime> get days => _days;
  List<EvtRec> get events => _events;

  /// load events for current month
  Future<void> _loadEvents() async {
    _events.clear(); // remove old data

    // create a query to apply on stored local timestamps.
    final q = LocalTimeRangeQuery(
      ref: _current,
      dayOffset: Duration(hours: _app.prefs.dayStartsH),
      unit: GroupFreq.month,
      overlapMode: OverlapMode.fullyInside,
    );

    Logger.root.info("Month view query: $q");

    _events = (await _app.db.evts.filteredLocalTime(range: q.toDbRange())).toList();

    // Compute summary from events
    summary = SummaryDataList(
      timePerEvent(_events).map((e) {
        final et = _app.evtTypeManager.resolveById(e.key);
        return SummaryItem(et?.name ?? "unknown", _app.colorFor(et), e.value);
      }).toList(),
    );
    // eventsPerDay();
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
    _loadEvents();
  }

  List<int> eventsPerDay() {
    final counts = List.filled(_days.length, 0);
    for (var e in _events) {
      final startLocal = e.start?.asUtcWithLocalValue;
      if (startLocal == null) continue;

      final idx = startLocal.day;
      counts[idx]++;
    }
    return counts;
  }

  bool isInMonth(DateTime day) => day.month == _current.month;
}
