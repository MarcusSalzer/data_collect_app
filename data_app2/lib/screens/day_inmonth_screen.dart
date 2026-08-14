import 'package:data_app2/app_state.dart';
import 'package:data_app2/blob_for_evt_cache.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/plots.dart';
import 'package:data_app2/view_models/day_inmonth_vm.dart';
import 'package:data_app2/view_models/month_vm.dart';
import 'package:data_app2/widgets/events_summary.dart';
import 'package:data_app2/widgets/evt_history_list.dart';
import 'package:data_app2/widgets/segm_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DayInmonthScreen extends StatelessWidget {
  final DateTime startDate;

  final MonthVm monthVm;

  const DayInmonthScreen(this.startDate, this.monthVm, {super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.select<AppState, AppPrefs>((a) => a.prefs);
    return ChangeNotifierProvider<DayInmonthVm>(
      create: (context) {
        final tm = context.read<AppState>().evtTypeManager;
        return DayInmonthVm(
          startDate,
          prefs.summaryMode,
          prefs.colorSpread,
          prefs.dayStartsH,
          tm,
          evtsForMonth: () => monthVm.eventList,
          stepToMonth: monthVm.stepTo,
        )..refresh();
      },
      child: Consumer<DayInmonthVm>(
        builder: (context, vm, child) {
          final thm = Theme.of(context);
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  spacing: 12,
                  children: [
                    Text(
                      Fmt.weekdayShort(vm.dt),
                      style: TextStyle(fontFamily: "monospace", color: thm.colorScheme.primary),
                    ),
                    Text(
                      Fmt.shortDate(vm.dt),
                      style: TextStyle(fontFamily: "monospace"),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    onPressed: () => vm.stepDay(-1), // step to day before
                    icon: Icon(Icons.keyboard_double_arrow_left, size: 30),
                  ),
                  IconButton(
                    onPressed: () => vm.stepDay(1), // step to day after
                    icon: Icon(Icons.keyboard_double_arrow_right, size: 30),
                  ),
                ],
                bottom: TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.pie_chart)),
                    Tab(icon: Icon(Icons.list)),
                  ],
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  spacing: 24,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      children: [
                        // select summary mode
                        SummaryModeSegmButton(vm.summaryMode, vm.setSummaryMode),
                        // select range inclusion
                        GenericSegmButton<RangeSummaryInclusionMode>(vm.rangeMode, vm.setRangeMode, [
                          (RangeSummaryInclusionMode.fullyInside, Icon(Icons.format_align_center)),
                          (RangeSummaryInclusionMode.endsIn, Icon(Icons.format_align_right)),
                          (RangeSummaryInclusionMode.endsInPlusFill, Icon(Icons.format_align_justify)),
                        ]),
                      ],
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final summary = vm.activeSummary;
                          if (summary == null) {
                            return SizedBox(
                              height: 300,
                              child: Center(
                                child: Text("loading"),
                              ),
                            );
                          }
                          return TabBarView(
                            children: [
                              Column(
                                spacing: 16,
                                children: [
                                  Expanded(
                                    child: EventPieChart(
                                      timings: summary.items.map((e) => MapEntry(e.name, e.duration)).toList(),
                                      colors: summary.items.map((e) => e.color).toList(),
                                    ),
                                  ),
                                  Expanded(
                                    child: EventDurationTable2(
                                      summary,
                                      Text(
                                        vm.summaryLabel, // depends on the current settings
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ChangeNotifierProvider<BlobForEvtCache>(
                                create: (context) =>
                                    BlobForEvtCache(context.read<AppState>().db.blobs, vm.evtsForMonth)..load(),
                                builder: (context, child) {
                                  final blobVm = context.watch<BlobForEvtCache>();
                                  return EvtHistoryList(
                                    vm.dayEvts,
                                    () {
                                      vm.load();
                                      blobVm.load();
                                    },
                                    blobsForEvt: blobVm.forEvt,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
