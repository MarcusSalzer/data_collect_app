import 'package:data_app2/app_state.dart';
import 'package:data_app2/event_stats_compute.dart';
import 'package:data_app2/stats.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';

class EventTypeViewModel extends ChangeNotifier {
  final int typeId;
  final AppState _app;

  bool _isLoading = false;
  List<EvtRec> _evts = [];
  Duration _totTime = Duration.zero;
  Map<int, int> _perWeekDay = {};

  /// Get the [EvtTypeRec] or a temporary "error message"-type
  EvtTypeRec get type =>
      _app.evtTypeRepo.resolveById(typeId) ??
      EvtTypeRec(name: "[ERROR: not found]");
  List<EvtRec> get evts => _evts;
  bool get isLoading => _isLoading;
  Duration get totTime => _totTime;
  Map<int, int> get perWeekDay => _perWeekDay;

  EventTypeViewModel(this.typeId, this._app) {
    load();
  }
  Future<void> load() async {
    _isLoading = true;
    _evts = [];
    notifyListeners();

    final evtsIsar =
        await _app.db.getEventsFilteredLocalTime(typeIds: [typeId]);
    _evts = evtsIsar.map((evIsar) => EvtRec.fromIsar(evIsar)).toList();

    _totTime = totalEventTime(_evts);

    // Events count per weekday
    _perWeekDay = valueCounts(
        _evts.map((e) => e.start?.asLocal.weekday).removeNulls,
        sorted: true,
        keys: Iterable.generate(7, (i) => i + 1));

    _isLoading = false;
    notifyListeners();
  }

  // get bins and hist values
  ({List<double> x, List<int> y})? getHistogram() {
    final points = evts.map(
      (e) {
        return e.duration?.inMinutes;
      },
    ).removeNulls;

    if (points.length < 4) {
      return null;
    }

    return histogram(points);
  }
}
