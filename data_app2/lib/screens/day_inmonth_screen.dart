import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/event_stats_compute.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/plots.dart';
import 'package:data_app2/screens/month_calendar_screen.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/widgets/event_history_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DayInmonthViewModel extends ChangeNotifier {
  DateTime dt;
  List<EvtRec> monthEvts;
  List<EvtRec> todayEvts = [];
  List<MapEntry<int, Duration>> tpe = [];
  DayInmonthViewModel(this.dt, this.monthEvts);

  void refresh() {
    todayEvts = monthEvts.where((e) {
      final start = e.start?.asLocal;
      if (start == null) {
        return false;
      }
      return start.startOfDay == dt;
    }).toList();

    tpe = timePerEvent(todayEvts);
    notifyListeners();
  }

  Future<void> load() async {
    await Future.delayed(Duration(seconds: 1));
    refresh();
    // TODO reload month!?
  }
}

class DayInmonthScreen extends StatelessWidget {
  final DateTime startDate;
  final MonthViewModel monthModel;

  const DayInmonthScreen(this.startDate, this.monthModel, {super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context, listen: false);
    return ChangeNotifierProvider<DayInmonthViewModel>(
      create: (context) {
        return DayInmonthViewModel(startDate, monthModel.events)..refresh();
      },
      child: Consumer<DayInmonthViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            appBar: AppBar(
              // TODO: too long title!
              title: Text(Fmt.verboseDate(vm.dt)),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  EventPieChart(
                    timings: vm.tpe
                        .map(
                          (e) => MapEntry(
                            app.evtTypeManager.resolveById(e.key)?.name ?? "?",
                            e.value,
                          ),
                        )
                        .toList(),
                    colors: vm.tpe
                        .map(
                          (e) => app.evtTypeManager
                              .resolveById(e.key)
                              ?.color
                              .inContext(context),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 30),
                  Text("Events", style: TextStyle(fontSize: 20)),
                  EventHistoryDisplay(
                    vm.todayEvts,
                    headingMode: null,
                    isScrollable: false,
                    reloadAction: vm.load,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
