import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/stats.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';

class EventModel extends ChangeNotifier {
  final AppState _app;
  final int? _nList; // default null -> all

  bool isLoading = true;

  List<EvtRec> _events = [];
  LinkedHashMap<int, int> _evtFreqs = LinkedHashMap<int, int>();
  List<EvtRec> get events => _events;
  Map<int, int> get evtFreqs => _evtFreqs;

  EventModel(AppState appState, {int? nList})
      : _app = appState,
        _nList = nList {
    load();
  }

  /// update latest-list and eventcounts
  Future<void> load() {
    return Future.wait([getLatest(), refreshCounts()]).then((_) {
      isLoading = false;
      notifyListeners();
    });
  }

  addEvent(String name, {DateTime? start, DateTime? end}) async {
    // final typeId = _app.eventTypeId(name);
    throw UnimplementedError("addevent not refactored");

    // Event evt;
    // if (typeId != null) {
    //   evt = await putEvent(Event.fromDateTimes(typeId, start, end));
    // } else {
    //   print("UNKNONW NEW");
    //   // create new event type
    //   final newTypeId = await _app.newEventType(name);
    //   evt = await putEvent(Event.fromDateTimes(newTypeId, start, end));
    // }
    // _events.insert(0, evt);
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
  Future<EvtRec> putEvent(EvtRec evt) async {
    final id = await _app.db.putEvent(evt.toIsar());
    // update id if new in DB
    evt.id = id;
    // print("added event $id");
    notifyListeners();
    return evt;
  }

  /// Update in memory list, of reverse chronological events
  Future<void> getLatest() async {
    _events = (await _app.db.latestEvents(_nList))
        .map((evIsar) => EvtRec.fromIsar(evIsar))
        .toList();
    notifyListeners();
  }

  List<int> eventSuggestions([int n = 20]) {
    var common = <int>[];
    for (var k in _evtFreqs.keys.take(n)) {
      // print("$k: ${_evtFreqs[k]}");
      common.add(k);
    }
    return common;
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
}
