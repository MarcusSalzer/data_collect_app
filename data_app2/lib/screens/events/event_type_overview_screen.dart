import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/event_type_view_model.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/plots.dart';
import 'package:data_app2/screens/events/event_type_detail_screen.dart';
import 'package:data_app2/widgets/event_history_display.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventTypeOverviewScreen extends StatelessWidget {
  final int typeId;

  const EventTypeOverviewScreen(this.typeId, {super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        return ChangeNotifierProvider<EventTypeViewModel>(
          create: (context) {
            return EventTypeViewModel(typeId, app);
          },
          child: DefaultTabController(
            length: 2,
            child: Consumer<EventTypeViewModel>(
              builder: (context, vm, child) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(vm.type.name, style: TextStyle(color: vm.type.color.inContext(context))),
                    actions: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (context) => EventTypeDetailScreen(vm.type))).then((value) {
                            vm.load();
                            if (value != null) {
                              // reload if anything changed
                            }
                          });
                        },
                        label: Text("edit"),
                        icon: Icon(Icons.edit),
                      ),
                    ],
                    bottom: TabBar(
                      tabs: [
                        const Tab(text: "Stats"),
                        const Tab(text: "Instances"),
                      ],
                    ),
                  ),
                  body: Builder(
                    builder: (context) {
                      if (vm.isLoading) {
                        return Center(child: Text("Loading..."));
                      }
                      if (vm.evts.isEmpty) {
                        return Center(child: Text("No instances"));
                      }
                      return TabBarView(
                        children: [
                          EventTypeStatsDisplay(model: vm),
                          EventHistoryDisplay(
                            vm.evts,
                            headingMode: GroupFreq.week,
                            isScrollable: true,
                            reloadAction: vm.load,
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
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
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("has ${model.evts.length} instances"),
              Text("total time: ${Fmt.durationHmVerbose(model.totTime)}"),
            ],
          ),
        ),
        Divider(),
        Builder(
          builder: (context) {
            final histData = model.getHistogram();
            if (histData == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text("Histogram needs more data"),
                ),
              );
            }

            return Padding(
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
                          histData.x.length,
                          (i) => FlSpot(
                            histData.x[i] / 60, // SECONDS -> MINUTES
                            histData.y[i].toDouble(),
                          ),
                        ),
                        color: model.type.color.inContext(context),
                        isCurved: true,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 30),
        Center(child: Text("Weekdays")),
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
                        barRods: [BarChartRodData(toY: e.value.toDouble(), color: model.type.color.inContext(context))],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
