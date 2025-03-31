// Keep current settings in memory, for convenient access

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

  AppState(this._db) {
    _db.loadPrefs(this);
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
}
