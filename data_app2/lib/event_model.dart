// ignore_for_file: avoid_print

import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/io.dart' as io;
import 'package:data_app2/stats.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';

class EventModel extends ChangeNotifier {
  final AppState _app;
  final bool _normStrip;
  final bool _normCase;
  final int? _nList; // default null -> all

  bool isLoading = true;

  List<Event> _events = [];
  LinkedHashMap<int, int> _evtFreqs = LinkedHashMap<int, int>();
  List<Event> get events => _events;
  Map<int, int> get evtFreqs => _evtFreqs;

  EventModel(AppState appState, {int? nList})
      : _app = appState,
        _normStrip = appState.normStrip,
        _normCase = appState.normCase,
        _nList = nList {
    _init();
  }

  /// update latest-list and eventcounts
  Future<void> _init() {
    return Future.wait([getLatest(), refreshCounts()]).then((_) {
      isLoading = false;
      notifyListeners();
    });
  }

  addEvent(String name, {DateTime? start, DateTime? end}) async {
    if (_normStrip) {
      name = name.trim();
    }
    if (_normCase) {
      name = name.toLowerCase();
    }

    final typeId = _app.eventTypeId(name);

    Event evt;
    if (typeId != null) {
      evt = await putEvent(Event(typeId, start: start, end: end));
    } else {
      print("UNKNONW NEW");
      // create new event type
      final newTypeId = await _app.newEventType(name);
      evt = await putEvent(Event(newTypeId, start: start, end: end));
    }
    _events.insert(0, evt);
  }

  delete(Event event) async {
    _app.db.deleteEvent(event.id);
    _events.remove(event);
    notifyListeners();
  }

  /// Save a new or updated event
  Future<Event> putEvent(Event evt) async {
    final id = await _app.db.putEvent(evt);
    evt.id = id;
    // print("added event $id");
    notifyListeners();
    return evt;
  }

  /// Update in memory list, of reverse chronological events
  Future<void> getLatest() async {
    _events = await _app.db.latestEvents(_nList);
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

  Future<int> importEvents(Iterable<EvtRec> recs) async {
    final c = await _app.db.importEventsDB(recs);
    getLatest();
    refreshCounts();

    notifyListeners();
    return c;
  }

  Future<int> exportEvents() async {
    final c =
        await io.exportEvents(await _app.db.getAllEvents(), _app.evtTypeToName);
    // print("exported $c events");
    return c;
  }
}
