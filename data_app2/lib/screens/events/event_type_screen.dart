import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/event_type_view_model.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/plots.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventTypeScreen extends StatelessWidget {
  final EventType type;

  final AppState app;
  late final String name;

  EventTypeScreen(this.app, {super.key, required this.type}) {
    name = type.name;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EventTypeViewModel>(
      create: (context) => EventTypeViewModel(type, app),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(name),
            bottom: TabBar(
              tabs: [
                const Tab(text: "Stats"),
                const Tab(text: "Instances"),
              ],
            ),
          ),
          body: Consumer<EventTypeViewModel>(
            builder: (context, model, child) {
              if (model.isLoading) {
                return Center(child: Text("Loading..."));
              }

              return TabBarView(children: [
                EventTypeStatsDisplay(model: model),
                EventListDisplay(evts: model.evts),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class EventListDisplay extends StatelessWidget {
  final List<Event> evts;

  const EventListDisplay({
    super.key,
    required this.evts,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: evts.length,
      itemBuilder: (context, index) {
        final evt = evts[index];

        return ListTile(
          title: Text(
              "${Fmt.dateTimeSecond(evt.start)} - ${Fmt.dateTimeSecond(evt.end)}"),
        );
      },
    );
  }
}

class EventTypeStatsDisplay extends StatelessWidget {
  final EventTypeViewModel model;
  const EventTypeStatsDisplay({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final (bins, hist) = model.getHistogram();

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("has ${model.evts.length} instances"),
              Text(
                "total time: ${Fmt.durationHM(model.totTime)}",
              ),
            ],
          ),
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
                      dotData: FlDotData(show: false))
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
                barGroups: model.perWeekDay.entries
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
  }
}
