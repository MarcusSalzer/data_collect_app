import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/util/event_stats_compute.dart';
import 'package:data_app2/util/stats.dart';
import 'package:flutter/material.dart';

/// Show overview of an event type.
class EvtTypeOverviewVm extends ChangeNotifier {
  final EvtTypeRec type;
  final AppState _app;

  // Stored once and reused
  final Color color;

  bool _isLoading = false;
  List<EvtRec> _evts = [];
  Duration _totTime = Duration.zero;
  Map<int, int> _perWeekDay = {};

  /// Get the [EvtTypeRec] or a temporary "error message"-type
  List<EvtRec> get evts => _evts;
  bool get isLoading => _isLoading;
  Duration get totTime => _totTime;
  Map<int, int> get perWeekDay => _perWeekDay;

  EvtTypeOverviewVm(this.type, this._app) : color = _app.evtTypeManager.colorFor(type, _app.prefs.colorSpread);

  Future<void> load() async {
    _isLoading = true;
    _evts = [];
    notifyListeners();

    _evts = (await _app.db.evts.filteredTypes([type.id])).toList();

    _totTime = totalEventTime(_evts);

    // Events count per weekday
    _perWeekDay = valueCounts(
      _evts.map((e) => e.start?.asLocal.weekday).removeNulls,
      sorted: true,
      keys: Iterable.generate(7, (i) => i + 1),
    );

    _isLoading = false;
    notifyListeners();
  }

  // get bins and hist values
  ({List<double> x, List<int> y})? getHistogram() {
    final points = evts.map((e) {
      return e.duration?.inSeconds;
    }).removeNulls;

    if (points.length < 4) {
      return null;
    }

    return histogram(points);
  }
}
