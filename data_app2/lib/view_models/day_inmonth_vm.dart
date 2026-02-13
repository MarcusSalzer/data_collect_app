import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/event_stats_compute.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class DayInmonthVm extends ChangeNotifier {
  final AppState _app;
  final DateTime dt;
  final List<EvtRec> monthEvts;
  List<EvtRec> todayEvts = [];
  List<MapEntry<int, Duration>> tpe = [];
  DayInmonthVm(this.dt, this._app, this.monthEvts);

  void refresh() {
    // create a query to apply on stored local timestamps.
    final q = LocalTimeRangeQuery(
      ref: dt,
      dayOffset: Duration(hours: _app.prefs.dayStartsH),
      unit: GroupFreq.day,
      overlapMode: OverlapMode.fullyInside,
    );

    Logger.root.info("Day view query: $q");

    todayEvts = monthEvts.where((e) => q.accepts(e.start, e.end)).toList();

    tpe = timePerEvent(todayEvts);

    notifyListeners();
  }

  Future<void> load() async {
    await Future.delayed(Duration(seconds: 1));
    refresh();
    // TODO reload month!?
  }
}
