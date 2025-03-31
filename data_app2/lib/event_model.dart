// ignore_for_file: avoid_print

import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

// TODO: can optimize counting and updating latest!
class EventModel extends ChangeNotifier {
  final DBService _db;
  final bool _normStrip;
  final bool _normCase;
  int? evtCount;
  final int nList = 100;

  List<Event> _events = [];
  LinkedHashMap<String, int> _evtFreqs = LinkedHashMap<String, int>();
  List<Event> get events => _events;

  EventModel(AppState appState)
      : _db = appState.db,
        _normStrip = appState.normStrip,
        _normCase = appState.normCase {
    _countEvents();
    updateLatest();
    refreshCounts();
  }

  addEvent(String name, {DateTime? start, DateTime? end}) async {
    if (_normStrip) {
      name = name.trim();
    }
    if (_normCase) {
      name = name.toLowerCase();
    }
    await saveEvent(Event(name, start: start, end: end));
    _countEvents();
    updateLatest();
  }

  delete(Event event) async {
    await _db.isar.writeTxn(() async {
      _db.isar.events.delete(event.id);
    });
    _countEvents();
    updateLatest();
  }

  /// Save a new or updated event
  Future<void> saveEvent(Event event) async {
    await _db.isar.writeTxn(() async {
      _db.isar.events.put(event);
    });
    notifyListeners();
  }

  Future<void> updateLatest() async {
    _events = await _db.isar.txn(() async {
      return _db.isar.events
          .where(sort: Sort.desc)
          .anyId()
          .limit(nList)
          .findAll();
    });
    notifyListeners();
  }

  void _countEvents() {
    _db.isar.events.count().then((c) {
      evtCount = c;
      notifyListeners();
    });
  }

  List<String> eventSuggestions([int n = 10]) {
    var common = <String>[];
    for (var k in _evtFreqs.keys.take(n)) {
      // print("$k: ${_evtFreqs[k]}");
      common.add(k);
    }
    return common;
  }

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
    notifyListeners();
  }

  Future<int> importEvents(String path) async {
    final c = await _db.importEventsCSV(path);
    updateLatest();
    _countEvents();
    refreshCounts();

    notifyListeners();
    return c;
  }
}
