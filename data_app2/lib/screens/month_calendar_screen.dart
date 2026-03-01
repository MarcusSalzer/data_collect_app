import 'dart:math';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/screens/day_inmonth_screen.dart';
import 'package:data_app2/view_models/month_vm.dart';
import 'package:data_app2/widgets/events_summary.dart';
import 'package:data_app2/widgets/summary_mode_segm_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:provider/provider.dart';

class MonthCalendarScreen extends StatefulWidget {
  const MonthCalendarScreen({super.key});

  @override
  State<MonthCalendarScreen> createState() => _MonthCalendarScreenState();
}

/// Stateful widget handles page control (VM only for month and summary business)
class _MonthCalendarScreenState extends State<MonthCalendarScreen> {
  final PageController _pageViewController = PageController();
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Subscribe to global prefs
    final prefs = context.select<AppState, AppPrefs>((a) => a.prefs);

    return ChangeNotifierProvider<MonthVm>(
      create: (createCtx) {
        // this does rebuild when AppState changes
        // unecessary, yes, but doesn't happen often.
        final app = createCtx.read<AppState>();
        return MonthVm(
          DateTime.now().startOfMonth,
          Duration(hours: prefs.dayStartsH),
          app.db,
          app.evtTypeManager,
          prefs.colorSpread,
          prefs.summaryMode,
        )..load();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Calendar"),
          bottom: PreferredSize(
            preferredSize: Size(double.infinity, 50),
            child: Consumer<MonthVm>(
              builder: (_, vm, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      vm.stepMonth(-1);
                    },
                    icon: Icon(Icons.keyboard_double_arrow_left),
                  ),
                  Expanded(child: Center(child: Text(DateFormat("MMMM yyyy").format(vm.currentMonth)))),
                  IconButton(
                    onPressed: () {
                      vm.stepMonth(1);
                    },
                    icon: Icon(Icons.keyboard_double_arrow_right),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Consumer<MonthVm>(
          builder: (context, vm, child) {
            final summary = vm.activeSummary;
            if (summary == null) {
              return Center(child: Text("loading..."));
            }

            final pages = [
              CalendarMonthDisplay(vm),
              EventDurationTable(summary, SummaryModeSegmButton(vm), height: 350, includeBar: true),
            ];
            return Column(
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
            );
          },
        ),
      ),
    );
  }

  void _updatePage(int index) {
    _pageViewController.animateToPage(index, duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
  }
}

class CalendarMonthDisplay extends StatelessWidget {
  final MonthVm model;

  const CalendarMonthDisplay(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    final events = model.eventList;
    if (events == null) return Text("Loading");

    return Center(
      child: Container(
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
            Text("Events: ${events.length}"),
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
    if (evtCounts == null) return Text("loading");

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
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => DayInmonthScreen(dt, monthModel.eventList)));
            }
          : null,
      child: Container(
        color: color,
        child: Center(child: Text("${dt.day}", style: tStyle)),
      ),
    );
  }
}
