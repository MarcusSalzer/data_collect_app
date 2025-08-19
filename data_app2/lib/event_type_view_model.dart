import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/event_stats_compute.dart';
import 'package:data_app2/stats.dart';
import 'package:flutter/material.dart';

class EventTypeViewModel extends ChangeNotifier {
  final EventType type;
  final AppState app;

  bool _isLoading = false;
  List<Event> _evts = [];
  Duration _totTime = Duration.zero;
  Map<int, int> _perWeekDay = {};

  List<Event> get evts => _evts;
  bool get isLoading => _isLoading;
  Duration get totTime => _totTime;
  Map<int, int> get perWeekDay => _perWeekDay;

  EventTypeViewModel(this.type, this.app) {
    load();
  }
  Future<void> load() async {
    _isLoading = true;
    _evts = [];
    notifyListeners();

    _evts = await app.db.getEventsFiltered(typeIds: [type.id]);

    _totTime = totalEventTime(_evts);

    // Events count per weekday
    _perWeekDay = valueCounts(_evts.map((e) => e.start?.weekday).removeNulls,
        sorted: true, keys: Iterable.generate(7, (i) => i + 1));

    _isLoading = false;
    notifyListeners();
  }

  // get bins and hist values
  (List<double>, List<int>) getHistogram() {
    return histogram(evts.map(
      (e) {
        final start = e.start;
        final end = e.end;
        if (start == null || end == null) return null;
        return end.difference(start).inMinutes;
      },
    ).removeNulls);
  }
}
