// Keep current settings in memory, for convenient access

import 'package:data_app2/event_stats_compute.dart';
import 'package:data_app2/extensions.dart';
import 'package:flutter/material.dart';
import 'package:data_app2/db_service.dart';

class AppState extends ChangeNotifier {
  bool _darkMode = true;
  // input normalization
  bool _normStrip = false;
  bool _normCase = false;
  final DBService _db;
  Map<String, int> _evtNameToType = {};
  Map<int, String> _evtTypeToName = {};

  // get preferences
  bool get isDarkMode => _darkMode;
  bool get normStrip => _normStrip;
  bool get normCase => _normCase;

  // get db instance
  DBService get db => _db;
  Map<String, int> get evtNameToType => _evtNameToType;
  Map<int, String> get evtTypeToName => _evtTypeToName;

  // keep track of today summary
  TodaySummaryData? todaySummary;

  AppState(this._db) {
    _db.loadPrefs().then((prefs) {
      if (prefs != null) {
        _darkMode = prefs.darkMode;
        _normStrip = prefs.normalizeStrip;
        _normCase = prefs.normalizeCase;
        notifyListeners();
      }
    });
    _db.loadEventTypes().then((types) {
      _evtNameToType = {};
      _evtTypeToName = {};
      for (var e in types) {
        _evtNameToType[e.name] = e.id;
        _evtTypeToName[e.id] = e.name;
      }
    });

    refreshSummary();
  }

  // TODO, store whole object to get colors etc.
  String? eventName(int typeId) {
    final name = _evtTypeToName[typeId];

    return name;
  }

  /// maybe only needed in a freeform text input?
  int? eventTypeId(String name) {
    final type = _evtNameToType[name];

    return type;
  }

  Future<int> newEventType(String name) async {
    final newTypeId = await _db.putEventType(name);
    _evtNameToType[name] = newTypeId;
    _evtTypeToName[newTypeId] = name;
    notifyListeners();
    return newTypeId;
  }

  setDarkMode(bool value) {
    _darkMode = value;
    _db.updatePrefs(this);
    notifyListeners();
  }

  setNormStrip(bool value) {
    _normStrip = value;
    _db.updatePrefs(this);
    notifyListeners();
  }

  setNormCase(bool value) {
    _normCase = value;
    _db.updatePrefs(this);
    notifyListeners();
  }

  /// For keeping summary after leaving events screen
  Future<void> refreshSummary() async {
    final evts =
        await db.getEventsFiltered(earliest: DateTime.now().startOfDay);

    final tpe = timePerEvent(evts, limit: 5);
    todaySummary = TodaySummaryData(tpe);
    notifyListeners();
  }
}

class TodaySummaryData {
  final List<MapEntry<int, Duration>> tpe;
  Duration get trackedTime => tpe.fold(Duration.zero, (p, c) => p + c.value);
  TodaySummaryData(this.tpe);
}
