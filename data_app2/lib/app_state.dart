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

  // get preferences
  bool get isDarkMode => _darkMode;
  bool get normStrip => _normStrip;
  bool get normCase => _normCase;

  // get db instance
  DBService get db => _db;

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

  Future<void> refreshSummary() async {
    final evts =
        await db.getEventsFiltered(earliest: DateTime.now().startOfDay);

    final tpe = timePerEvent(evts, limit: 5);
    todaySummary = TodaySummaryData(tpe);
    notifyListeners();
  }
}

class TodaySummaryData {
  final List<MapEntry<String, Duration>> tpe;
  Duration get trackedTime => tpe.fold(Duration.zero, (p, c) => p + c.value);
  TodaySummaryData(this.tpe);
}
