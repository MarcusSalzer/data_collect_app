import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/event_stats_compute.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/screens/events/plots.dart';
import 'package:data_app2/stats.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EventTypeScreen extends StatelessWidget {
  final String name;

  final AppState appState;
  late final Future<List<Event>> evtsF;

  EventTypeScreen(this.appState, {super.key, required this.name}) {
    evtsF = appState.db.getEventsFiltered(names: [name]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: FutureBuilder(
        future: evtsF,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Text("Loading events...");
          }
          if (snap.hasError) {
            return Text(snap.error.toString());
          }
          final evts = snap.data;
          if (!snap.hasData || evts == null) {
            return Text("No data!");
          }

          final totTime = totalEventTime(evts);
          final (bins, hist) = histogram(
            evts.map(
              (e) {
                final start = e.start;
                final end = e.end;
                if (start == null || end == null) return null;
                return end.difference(start).inMinutes;
              },
            ).removeNulls,
          );
          final perWeekDay = valueCounts(
              evts.map((e) => e.start?.weekday).removeNulls,
              sorted: true,
              keys: Iterable.generate(7, (i) => i + 1));
          // print(perWeekDay);

          return ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("has ${evts.length} instances"),
                  Text(
                    "total time: ${Fmt.durationHM(totTime)}",
                  ),
                ],
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: minimalTitlesData("Duration", "count"),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            hist.length,
                            (i) => FlSpot(
                              bins[i],
                              hist[i].toDouble(),
                            ),
                          ),
                          isCurved: true,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Center(
                child: Text("Weekdays"),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AspectRatio(
                  aspectRatio: 2,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: minimalTitlesData("Weekday", "count"),
                      barGroups: perWeekDay.entries
                          .map(
                            (e) => BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.toDouble(),
                                )
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
