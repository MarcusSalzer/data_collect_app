// ignore_for_file: avoid_print

import 'package:datacollectv2/db_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class EventModel extends ChangeNotifier {
  final DBService _db;
  int? evtCount;
  final int nList = 10;

  List<Event> _events = [];
  List<Event> get events => _events;

  EventModel(this._db) {
    _countEvents();
    updateLatest();
  }

  addEvent(String name, {DateTime? start, DateTime? end}) async {
    await saveEvent(Event(name, start: start, end: end));
    _countEvents();
    updateLatest();
  }

  /// Save a new event
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
}
