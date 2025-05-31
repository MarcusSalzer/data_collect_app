// ignore_for_file: avoid_print

import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/stats.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class EventModel extends ChangeNotifier {
  final DBService _db;
  final bool _normStrip;
  final bool _normCase;
  final int? _nList; // default null -> all

  bool isLoading = true;

  List<Event> _events = [];
  LinkedHashMap<String, int> _evtFreqs = LinkedHashMap<String, int>();
  List<Event> get events => _events;
  Map<String, int> get evtFreqs => _evtFreqs;

  EventModel(AppState appState, {int? nList})
      : _db = appState.db,
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
    final evt = await putEvent(Event(name, start: start, end: end));
    _events.insert(0, evt);
  }

  delete(Event event) async {
    await _db.isar.writeTxn(() async {
      _db.isar.events.delete(event.id);
    });
    _events.remove(event);
    notifyListeners();
  }

  /// Save a new or updated event
  Future<Event> putEvent(Event evt) async {
    final id = await _db.isar.writeTxn(() async {
      return _db.isar.events.put(evt);
    });
    evt.id = id;
    // print("added event $id");
    notifyListeners();
    return evt;
  }

  /// Update in memory list, of reverse chronological events
  Future<void> getLatest() async {
    _events = [];
    _events = await _db.isar.txn(() async {
      return _db.isar.events
          .where()
          .anyId()
          .sortByStartDesc()
          .optional(_nList != null, (q) => q.limit(_nList!))
          .findAll();
    });
    notifyListeners();
  }

  List<String> eventSuggestions([int n = 20]) {
    var common = <String>[];
    for (var k in _evtFreqs.keys.take(n)) {
      // print("$k: ${_evtFreqs[k]}");
      common.add(k);
    }
    return common;
  }

  /// Count each event type
  Future<void> refreshCounts() async {
    final evts = await _db.isar.txn(() async {
      return _db.isar.events.where().anyId().findAll();
    });

    var counts = valueCounts(evts.map((e) => e.name));

    _evtFreqs = LinkedHashMap.fromEntries(counts.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      ));
  }

  Future<(Iterable<EvtRec>, EvtRecSummary)> prepareImportEvts(
      String path) async {
    final recs = await importEvtsCSV(path);
    final summary = EvtRecSummary(recs);
    return (recs, summary);
  }

  Future<int> importEvents(Iterable<EvtRec> recs) async {
    final c = await _db.importEventsDB(recs);
    getLatest();
    refreshCounts();

    notifyListeners();
    return c;
  }

  Future<int> exportEvents() async {
    final c = await _db.exportEvents();
    // print("exported $c events");
    return c;
  }

  Future<int> normalizeLowerAll() async {
    _events = []; // remove in memory events for consistency
    isLoading = true;
    notifyListeners();

    final c = await _db.isar.writeTxn(
      () async {
        final evts = await _db.isar.events.where().findAll();
        final uptdt = await _db.isar.events
            .putAll(evts.map((e) => e..name = e.name.toLowerCase()).toList());
        return uptdt.length;
      },
    );
    await _init();
    return c;
  }

  Future<int> normalizeStripAll() async {
    _events = []; // remove in memory events for consistency
    isLoading = true;
    notifyListeners();

    final c = await _db.isar.writeTxn(
      () async {
        final evts = await _db.isar.events.where().findAll();
        final uptdt = await _db.isar.events
            .putAll(evts.map((e) => e..name = e.name.trim()).toList());
        return uptdt.length;
      },
    );
    await _init();
    return c;
  }
}
