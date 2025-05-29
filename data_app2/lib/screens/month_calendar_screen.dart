import 'dart:math';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/extensions.dart';
import 'package:data_app2/screens/day_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

/// Handle data for showing stats for a month
class MonthViewModel extends ChangeNotifier {
  DBService _db;
  DateTime _current = DateTime.now().startOfMonth;

  List<DateTime> _days = [];
  List<Event> _events = [];
  late Future<void> loadFuture;

  MonthViewModel(this._db) {
    loadFuture = _loadEvents();
    _makeDayGrid();
  }

  DateTime get current => _current;
  List<DateTime> get days => _days;
  List<Event> get events => _events;

  /// load events for current month
  Future<void> _loadEvents() async {
    _events.clear(); // remove old data
    final evts = await _db.getEventsFiltered(
        earliest: _current,
        latest: DateUtils.addMonthsToMonthDate(_current, 1));
    _events = evts;
    // eventsPerDay();
    notifyListeners();
  }

  /// Make 6x7 grid of days
  void _makeDayGrid() {
    final offset = _current.monthFirstWeekday;

    _days = List.generate(42,
        (i) => DateUtils.addDaysToDate(_current.startOfMonth, i - offset + 2));
  }

  /// Move to a new month and reload data
  void stepMonth(int offset) {
    _current = DateUtils.addMonthsToMonthDate(current, offset);
    _makeDayGrid();
    notifyListeners();
    _loadEvents();
  }

  List<int> eventsPerDay() {
    final counts = List.filled(_days.length, 0);
    for (var e in _events) {
      final s = e.start;
      if (s == null) continue;

      final idx = s.day;
      counts[idx]++;
    }
    return counts;
  }

  bool isInMonth(DateTime day) => day.month == _current.month;
}

class MonthCalendarScreen extends StatelessWidget {
  final AppState appstate;

  const MonthCalendarScreen(this.appstate, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MonthViewModel>(
      create: (context) => MonthViewModel(appstate.db),
      child: Consumer<MonthViewModel>(
        builder: (context, model, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Calendar"),
            ),
            body: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        model.stepMonth(-1);
                      },
                      icon: Icon(Icons.keyboard_double_arrow_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                            DateFormat("MMMM yyyy").format(model._current)),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        model.stepMonth(1);
                      },
                      icon: Icon(Icons.keyboard_double_arrow_right),
                    ),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: "MTWTFSS".characters.map((c) => Text(c)).toList(),
                ),
                Divider(),
                Expanded(
                  child: CalendarGrid(model),
                ),
                Divider(),
                Text("Events? ${model.events.length}"),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CalendarGrid extends StatelessWidget {
  final MonthViewModel model;
  const CalendarGrid(
    this.model, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final evtCounts = model.eventsPerDay();
    final maxCount = evtCounts.fold(1, (p, c) => max(p, c));
    return GridView.builder(
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemCount: model.days.length,
      itemBuilder: (context, index) {
        final d = model.days[index];
        return CalDayTile(
          dt: d,
          active: model.isInMonth(d),
          weight: evtCounts[index] / maxCount,
        );
      },
    );
  }
}

class CalDayTile extends StatelessWidget {
  const CalDayTile({
    super.key,
    required this.dt,
    required this.active,
    required this.weight,
  });

  final DateTime dt;
  final bool active;
  final float weight;

  @override
  Widget build(BuildContext context) {
    final color = Colors.red.withAlpha((255 * weight).round());
    // final theme = Theme.of(context);
    var tStyle = TextStyle(fontFamily: "monospace", fontSize: 20);
    if (!active) {
      tStyle = tStyle.copyWith(color: Colors.grey);
    }
    if (dt.isToday()) {
      tStyle = tStyle.copyWith(
          decoration: TextDecoration.underline, decorationThickness: 2);
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => DayScreen(dt),
        ));
      },
      child: Container(
        color: color,
        child: Center(
            child: Text(
          "${dt.day}",
          style: tStyle,
        )),
      ),
    );
  }
}
