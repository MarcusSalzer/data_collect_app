import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/stats.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';

class EventTypeIndexViewModel extends ChangeNotifier {
  final AppState _app;

  LinkedHashMap<int, int>? _evtFreqs;
  LinkedHashMap<int, int>? get evtFreqs => _evtFreqs;

  Iterable<int> danglingTypeRefs = {};

  EvtTypeRec? eventType(int id) {
    return _app.evtTypeRepo.resolveById(id);
  }

  List<EvtTypeRec> get typesSorted {
    final freqs = _evtFreqs;
    if (freqs == null) {
      return [];
    }

    // Copy list of all types
    final types = [..._app.evtTypeRepo.all];

    // Sort by descending (zeros at end)
    types.sort((a, b) {
      final af = freqs[a.id ?? -1] ?? 0;
      final bf = freqs[b.id ?? -1] ?? 0;
      // Higher freq first
      return bf.compareTo(af);
    });

    return types;
  }

  void _onRepoChanged() {
    notifyListeners();
  }

  EventTypeIndexViewModel(this._app) {
    // propagate updates from eventType repo
    _app.evtTypeRepo.addListener(_onRepoChanged);
  }

  Future load() async {
    // Check for dangling type references
    danglingTypeRefs = await _app.evtTypeRepo.danglingTypeRefs();
    await refreshCounts();
    notifyListeners();
  }

  /// Count each event type
  Future<void> refreshCounts() async {
    final evts = await _app.db.getAllEvents();

    var counts = valueCounts(evts.map((e) => e.typeId));

    _evtFreqs = LinkedHashMap.fromEntries(counts.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      ));
  }

  @override
  void dispose() {
    _app.evtTypeRepo.removeListener(_onRepoChanged);
    super.dispose();
  }
}
