// ignore_for_file: avoid_print

import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class EventModel extends ChangeNotifier {
  final DBService _db;
  final bool _normStrip;
  final bool _normCase;
  final int nList = 100;

  bool isLoading = true;

  List<Event> _events = [];
  LinkedHashMap<String, int> _evtFreqs = LinkedHashMap<String, int>();
  List<Event> get events => _events;

  EventModel(AppState appState)
      : _db = appState.db,
        _normStrip = appState.normStrip,
        _normCase = appState.normCase {
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
    await saveEvent(Event(name, start: start, end: end));
  }

  delete(Event event) async {
    await _db.isar.writeTxn(() async {
      _db.isar.events.delete(event.id);
    });
    _events.remove(event);
    notifyListeners();
  }

  /// Save a new or updated event
  Future<void> saveEvent(Event event) async {
    final id = await _db.isar.writeTxn(() async {
      return _db.isar.events.put(event);
    });
    event.id = id;
    _events.add(event);
    // print("added event $id");
    notifyListeners();
  }

  Future<void> getLatest() async {
    _events = [];
    _events = await _db.isar.txn(() async {
      return _db.isar.events
          .where(sort: Sort.asc)
          .anyId()
          .limit(nList)
          .findAll();
    });
    notifyListeners();
  }

  List<String> eventSuggestions([int n = 10]) {
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

    var counts = <String, int>{};
    for (var evt in evts) {
      counts[evt.name] = (counts[evt.name] ?? 0) + 1;
    }
    _evtFreqs = LinkedHashMap.fromEntries(counts.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      ));
  }

  Future<int> importEvents(String path) async {
    final c = await _db.importEventsCSV(path);
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
