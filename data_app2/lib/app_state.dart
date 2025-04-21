// Keep current settings in memory, for convenient access

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
    todaySummary = null;
    notifyListeners();
    final f = Future<String>.delayed(
      const Duration(seconds: 1),
      () => 'Data Loaded',
    );
    final t = await f;
    final evts =
        await db.getEventsFiltered(earliest: DateTime.now().startOfDay);
    todaySummary = TodaySummaryData("$t: ${evts.length}");
    notifyListeners();
  }
}

class TodaySummaryData {
  final String data;
  TodaySummaryData(this.data);
}
