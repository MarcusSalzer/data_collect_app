import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/plots.dart';
import 'package:data_app2/view_models/day_inmonth_vm.dart';
import 'package:data_app2/view_models/month_vm.dart';
import 'package:data_app2/widgets/event_history_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DayInmonthScreen extends StatelessWidget {
  final DateTime startDate;
  final MonthVm monthModel;

  const DayInmonthScreen(this.startDate, this.monthModel, {super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context, listen: false);
    final colorSpread = app.prefs.colorSpread;
    return ChangeNotifierProvider<DayInmonthVm>(
      create: (context) {
        return DayInmonthVm(startDate, app, monthModel.events)..refresh();
      },
      child: Consumer<DayInmonthVm>(
        builder: (context, vm, child) {
          return Scaffold(
            appBar: AppBar(title: Text(Fmt.date(vm.dt))),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  EventPieChart(
                    timings: vm.tpe
                        .map((e) => MapEntry(app.evtTypeManager.typeFromId(e.key)?.name ?? "?", e.value))
                        .toList(),
                    colors: vm.tpe.map((e) => app.evtTypeManager.colorForId(e.key, colorSpread)).toList(),
                  ),
                  SizedBox(height: 30),
                  Text("Events (${vm.tpe.length})", style: TextStyle(fontSize: 20)),
                  EventHistoryDisplay(vm.todayEvts, headingMode: null, isScrollable: false, reloadAction: vm.load),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
