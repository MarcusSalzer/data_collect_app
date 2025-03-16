// Keep current settings in memory, for convenient access

import 'package:flutter/material.dart';
import 'package:datacollectv2/db_service.dart';

class AppState extends ChangeNotifier {
  bool _darkMode = true;
  final DBService _db;
  DBService get db => _db;

  AppState(this._db) {
    _db.loadPrefs(this);
  }

  setDarkMode(bool value) {
    _darkMode = value;
    _db.updatePrefs(this);

    notifyListeners();
  }

  isDarkMode() {
    return _darkMode;
  }
}
