import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/stats.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';

const nFreq = 400;

class EventCreateViewModel extends ChangeNotifier {
  final AppState _app;
  final int? _nList; // default null -> all

  bool isLoading = true;

  List<EvtRec> _events = [];
  LinkedHashMap<int, int> _evtFreqs = LinkedHashMap<int, int>();
  List<EvtRec> get events => _events;
  Map<int, int> get evtFreqs => _evtFreqs;

  EventCreateViewModel(AppState appState)
      : _app = appState,
        _nList = 50 {
    load();
  }

  /// update latest-list and eventcounts
  Future<void> load() {
    return Future.wait([getLatest(), refreshCounts()]).then((_) {
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addEventByType(int typeId,
      {DateTime? start, DateTime? end}) async {
    final evtRec = EvtRec.inCurrentTZ(typeId: typeId, start: start, end: end);
    final newId = await _app.db.putEvent(evtRec.toIsar());
    evtRec.id = newId;
    _events.add(evtRec);
    notifyListeners();
  }

  Future<void> addEventByName(String name,
      {DateTime? start, DateTime? end}) async {
    final typeId = await _app.evtTypeRepo.resolveOrCreate(name: name);
    await addEventByType(typeId, start: start, end: end);
  }

  delete(EvtRec event) async {
    final id = event.id;
    if (id != null) {
      // has id? means alredy stored in DB
      _app.db.deleteEvent(id);
    }
    _events.remove(event);
    notifyListeners();
  }

  /// Save a new or updated event
  Future<EvtRec> updateEvent(EvtRec evt) async {
    final id = await _app.db.putEvent(evt.toIsar());
    // update id if new in DB
    evt.id = id;
    notifyListeners();
    return evt;
  }

  /// Update in memory list, of reverse chronological events
  Future<void> getLatest() async {
    _events = (await _app.db.latestEvents(_nList))
        .map((evIsar) => EvtRec.fromIsar(evIsar))
        .toList()
        .reversed
        .toList();
    notifyListeners();
  }

  List<int> eventSuggestions([int n = 20]) {
    var common = <int>[];
    for (var k in _evtFreqs.keys.take(n)) {
      common.add(k);
    }
    return common;
  }

  /// Count each event type
  Future<void> refreshCounts() async {
    final evts = await _app.db.latestEvents(nFreq);

    var counts = valueCounts(evts.map((e) => e.typeId));

    _evtFreqs = LinkedHashMap.fromEntries(counts.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      ));
  }
}
