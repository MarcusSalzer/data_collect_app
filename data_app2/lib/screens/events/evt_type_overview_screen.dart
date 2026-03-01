import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/evt_type_overview_vm.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/plots.dart';
import 'package:data_app2/screens/events/event_type_detail_screen.dart';
import 'package:data_app2/widgets/event_history_display.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EvtTypeOverviewScreen extends StatelessWidget {
  final EvtTypeRec type;

  const EvtTypeOverviewScreen(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EvtTypeOverviewVm>(
      create: (createCtx) {
        final app = createCtx.read<AppState>();
        return EvtTypeOverviewVm(type, app)..load();
      },
      child: DefaultTabController(
        length: 2,
        child: Consumer<EvtTypeOverviewVm>(
          builder: (context, vm, child) {
            return Scaffold(
              appBar: AppBar(
                title: Text(vm.type.name, style: TextStyle(color: vm.color)),
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (context) => EventTypeDetailScreen(vm.type))).then((value) {
                        // reload
                        if (value == "deleted" && context.mounted) {
                          // Extra pop after deleted
                          Navigator.of(context).pop();
                        } else {
                          vm.load();
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
                      const _EventTypeStatsDisplay(),
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
  }
}

class _EventTypeStatsDisplay extends StatelessWidget {
  const _EventTypeStatsDisplay();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EvtTypeOverviewVm>();
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("has ${vm.evts.length} instances"),
              Text("total time: ${Fmt.durationHmVerbose(vm.totTime)}"),
            ],
          ),
        ),
        Divider(),
        Builder(
          builder: (context) {
            final histData = vm.getHistogram();
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
                        color: vm.color,
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
                barGroups: vm.perWeekDay.entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [BarChartRodData(toY: e.value.toDouble(), color: vm.color)],
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
