import 'dart:math';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/screens/day_inmonth_screen.dart';
import 'package:data_app2/view_models/month_vm.dart';
import 'package:data_app2/widgets/events_summary.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:provider/provider.dart';

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
    return ChangeNotifierProvider<MonthVm>(
      create: (context) => MonthVm(widget.appstate),
      child: Consumer<MonthVm>(
        builder: (context, model, child) {
          final pages = [CalendarMonthDisplay(model), MonthSummaryDisplay(model)];
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
                      Expanded(child: Center(child: Text(DateFormat("MMMM yyyy").format(model.currentMonth)))),
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
                      icon: Icon(Icons.arrow_left),
                    ),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updatePage(int index) {
    _pageViewController.animateToPage(index, duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
  }
}

/// event time table and pie chart for a month
class MonthSummaryDisplay extends StatelessWidget {
  final MonthVm model;

  const MonthSummaryDisplay(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    if (model.events.isEmpty) {
      return Center(child: Text("No events in ${Fmt.monthName(model.currentMonth)}"));
    }
    final summary = model.summary;
    if (summary == null) {
      return Center(child: Text("loading..."));
    }
    return Column(
      children: [
        EventsSummary(title: Fmt.monthName(model.currentMonth), summary: summary, listHeight: 350),
        // Expanded(
        //   child: Padding(
        //     padding: const EdgeInsets.all(8.0),
        //     child: EventPieChart(
        //       timings: groupLastEntries(model.tpe, n: 16)
        //           .map((g) => MapEntry(g.key.toString(), g.value))
        //           .toList(),
        //       colors: Colors.primaries,
        //       nTitles: 5,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

class CalendarMonthDisplay extends StatelessWidget {
  final MonthVm model;

  const CalendarMonthDisplay(this.model, {super.key});

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
  final MonthVm model;
  const CalendarGrid(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    final evtCounts = model.eventsPerDay();
    final maxCount = evtCounts.fold(1, (p, c) => max(p, c));
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
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
  const CalDayTile({super.key, required this.dt, required this.active, required this.weight});

  final DateTime dt;
  final bool active;
  final float weight;

  @override
  Widget build(BuildContext context) {
    final monthModel = Provider.of<MonthVm>(context, listen: false);
    final color = Colors.red.withAlpha((255 * weight).round());
    // final theme = Theme.of(context);
    var tStyle = TextStyle(fontFamily: "monospace", fontSize: 20);
    if (!active) {
      tStyle = tStyle.copyWith(color: Colors.grey);
    }
    if (dt.isToday()) {
      tStyle = tStyle.copyWith(decoration: TextDecoration.underline, decorationThickness: 2);
    }

    return InkWell(
      onTap: active
          ? () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => DayInmonthScreen(dt, monthModel)));
            }
          : null,
      child: Container(
        color: color,
        child: Center(child: Text("${dt.day}", style: tStyle)),
      ),
    );
  }
}
