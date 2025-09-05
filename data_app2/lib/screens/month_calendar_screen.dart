import 'dart:math';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/event_stats_compute.dart';
import 'package:data_app2/extensions.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/plots.dart';
import 'package:data_app2/screens/day_inmonth_screen.dart';
import 'package:data_app2/stats.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/widgets/events_summary.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

/// Handle data for showing stats for a month
class MonthViewModel extends ChangeNotifier {
  final DBService _db;
  DateTime _current = DateTime.now().startOfMonth;
  List<MapEntry<int, Duration>> tpe = [];

  List<DateTime> _days = [];
  List<EvtRec> _events = [];
  late Future<void> loadFuture;

  MonthViewModel(this._db) {
    loadFuture = _loadEvents();
    _makeDayGrid();
  }

  DateTime get currentMonth => _current;
  List<DateTime> get days => _days;
  List<EvtRec> get events => _events;

  /// load events for current month
  Future<void> _loadEvents() async {
    _events.clear(); // remove old data
    final evts = await _db.getEventsFiltered(
        earliest: _current,
        latest: DateUtils.addMonthsToMonthDate(_current, 1));
    _events = evts.map((e) => EvtRec.fromIsar(e)).toList();
    tpe = timePerEvent(_events);
    // eventsPerDay();
    notifyListeners();
  }

  /// Make 6x7 grid of days
  void _makeDayGrid() {
    final offset = _current.monthFirstWeekday;

    _days = List.generate(42,
        (i) => DateUtils.addDaysToDate(_current.startOfMonth, i - offset + 1));
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
      final startLocal = e.start?.asLocal;
      if (startLocal == null) continue;

      final idx = startLocal.day;
      counts[idx]++;
    }
    return counts;
  }

  bool isInMonth(DateTime day) => day.month == _current.month;
}

class MonthCalendarScreen extends StatefulWidget {
  final AppState appstate;

  const MonthCalendarScreen(this.appstate, {super.key});

  @override
  State<MonthCalendarScreen> createState() => _MonthCalendarScreenState();
}

class _MonthCalendarScreenState extends State<MonthCalendarScreen> {
  final PageController _pageViewController = PageController();
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MonthViewModel>(
      create: (context) => MonthViewModel(widget.appstate.db),
      child: Consumer<MonthViewModel>(
        builder: (context, model, child) {
          final pages = [
            CalendarMonthDisplay(model),
            MonthSummaryDisplay(model),
          ];
          return Scaffold(
            appBar: AppBar(
              title: Text("Calendar"),
              bottom: PreferredSize(
                preferredSize: Size(double.infinity, 45),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
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
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageViewController,
                    onPageChanged: (value) {
                      setState(() {
                        _pageIndex = value;
                      });
                    },
                    scrollDirection: Axis.vertical,
                    children: pages,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: () {
                          if (_pageIndex > 0) {
                            _updatePage(_pageIndex - 1);
                          }
                        },
                        icon: Icon(Icons.arrow_left)),
                    Text("page $_pageIndex"),
                    IconButton(
                      onPressed: () {
                        if (_pageIndex < pages.length - 1) {
                          _updatePage(_pageIndex + 1);
                        }
                      },
                      icon: Icon(Icons.arrow_right),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _updatePage(int index) {
    _pageViewController.animateToPage(
      index,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }
}

/// event time table and pie chart for a month
class MonthSummaryDisplay extends StatelessWidget {
  final MonthViewModel model;

  const MonthSummaryDisplay(
    this.model, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context, listen: false);
    if (model.events.isEmpty) {
      return Center(
        child: Text("No events in ${Fmt.monthName(model.currentMonth)}"),
      );
    }
    return Column(
      children: [
        EventsSummary(
          title: Fmt.monthName(model.currentMonth),
          tpe: model.tpe
              .map(
                (e) => MapEntry(
                    app.evtTypeRepo.resolveById(e.key)?.name ?? "unknown",
                    e.value),
              )
              .toList(),
          colors: Colors.primaries,
          listHeight: 350,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: EventPieChart(
              timings: groupLastEntries(model.tpe, n: 16)
                  .map((g) => MapEntry(g.key.toString(), g.value))
                  .toList(),
              colors: Colors.primaries,
              nTitles: 5,
            ),
          ),
        ),
      ],
    );
  }
}

class CalendarMonthDisplay extends StatelessWidget {
  final MonthViewModel model;

  const CalendarMonthDisplay(
    this.model, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.white10,
        margin: EdgeInsets.all(4),
        padding: EdgeInsets.all(4),
        constraints: BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: "MTWTFSS".characters.map((c) => Text(c)).toList(),
            ),
            Divider(),
            AspectRatio(
              aspectRatio: 7 / 6 - 0.01, // to match grid
              child: CalendarGrid(model),
            ),
            Divider(),
            Text("Events: ${model.events.length}"),
          ],
        ),
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
      physics: NeverScrollableScrollPhysics(),
      itemCount: model.days.length,
      itemBuilder: (context, index) {
        final d = model.days[index];
        final isActive = model.isInMonth(d);
        return CalDayTile(
          dt: d,
          active: isActive,
          // use weight for corresponding day if in current month
          weight: isActive ? evtCounts[d.day] / maxCount : 0,
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
    final monthModel = Provider.of<MonthViewModel>(context, listen: false);
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
      onTap: active
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DayInmonthScreen(dt, monthModel),
                ),
              );
            }
          : null,
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
