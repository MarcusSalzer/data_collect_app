// Keep current settings in memory, for convenient access

import 'package:data_app2/event_stats_compute.dart';
import 'package:data_app2/event_type_repository.dart';
import 'package:data_app2/extensions.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';
import 'package:data_app2/db_service.dart';

class AppState extends ChangeNotifier {
  bool _darkMode = true;
  // input normalization
  bool _normStrip = false;
  bool _normCase = false;
  final DBService _db;
  final EvtTypeRepositoryPersist _evtTypeRepo;

  // get preferences
  bool get isDarkMode => _darkMode;
  bool get normStrip => _normStrip;
  bool get normCase => _normCase;

  // get db instance & event types
  DBService get db => _db;

  /// Get the singleton type repository
  EvtTypeRepositoryPersist get evtTypeRepo => _evtTypeRepo;

  // keep track of today summary
  TodaySummaryData? todaySummary;

  AppState(this._db) : _evtTypeRepo = EvtTypeRepositoryPersist(db: _db) {
    _db.loadPrefs().then((prefs) {
      if (prefs != null) {
        _darkMode = prefs.darkMode;
        _normStrip = prefs.normalizeStrip;
        _normCase = prefs.normalizeCase;
        notifyListeners();
      }
    });
    _db.getEventTypes().then((types) {
      _evtTypeRepo.fillFromIsar(types);
    });

    // check dangling types (move this?)
    evtTypeRepo.danglingTypeRefs();

    refreshSummary();
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
    final evts = await db.getEventsFilteredLocalTime(
        earliest: LocalDateTime.fromDateTimeLocalTZ(DateTime.now().startOfDay));

    final tpe = timePerEvent(evts.map((e) => EvtRec.fromIsar(e)), limit: 5);
    todaySummary = TodaySummaryData(tpe);
    notifyListeners();
  }
}

class TodaySummaryData {
  final List<MapEntry<int, Duration>> tpe;
  Duration get trackedTime => tpe.fold(Duration.zero, (p, c) => p + c.value);
  TodaySummaryData(this.tpe);
}
