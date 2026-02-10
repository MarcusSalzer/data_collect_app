// Keep current settings in memory, for convenient access

import 'dart:io';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/today_summary_data.dart';
import 'package:data_app2/prefs_io.dart';
import 'package:data_app2/style.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/event_type_manager.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:data_app2/db_service.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

class AppState extends ChangeNotifier {
  // remember preferences
  AppPrefs _prefs;

  final Directory _userStoreDir;
  final DBService _db;
  final EvtTypeManagerPersist _evtTypeManager;

  /// A user accessible directory for data
  Directory get userStoreDir => _userStoreDir;

  /// All preferences
  AppPrefs get prefs => _prefs;
  // deprecated individual getters?
  bool get isDarkMode => _prefs.colorSchemeMode == ColorSchemeMode.dark;
  bool get autoLowerCase => _prefs.autoLowerCase;
  LogLevel get logLevel => _prefs.logLevel;
  TextSearchMode get textSearchMode => _prefs.textSearchMode;

  // get db instance & event types
  DBService get db => _db;
  File get prefsFile => _prefsFile;

  /// Get the singleton type repository
  EvtTypeManagerPersist get evtTypeManager => _evtTypeManager;

  // keep track of today summary
  TodaySummaryDataByType? todaySummary;

  final File _prefsFile;

  /// Initialize appstate.
  ///
  /// Will also get a [EvtTypeManagerPersist] and fill evt-type-cache
  AppState(this._db, this._prefs, this._userStoreDir, this._prefsFile) : _evtTypeManager = EvtTypeManagerPersist(_db) {
    // Fill the cache
    _db.allTypesAndCats().then((r) {
      _evtTypeManager.reloadFromModels(r.$1, r.$2);
    });

    // check dangling types (move this?)
    _db.danglingTypeRefs().then((d) {
      final count = d.length;
      final msg = "has $count dangling type-refs";
      if (count > 0) {
        Logger.root.warning(msg);
      }
      Logger.root.info(msg);
    });
  }

  // --- Preference updating ---

  Future<void> setColorScheme(ColorSchemeMode value) async {
    await updatePrefs(_prefs.copyWith(colorSchemeMode: value));
    Logger.root.info("updated prefs: colorSchemeMode=$value");
  }

  Future<void> setAutoLowerCase(bool value) async {
    await updatePrefs(_prefs.copyWith(autoLowerCase: value));
    Logger.root.info("updated prefs: autoLowercase=$value");
  }

  Future<void> setLogLevel(LogLevel value) async {
    await updatePrefs(_prefs.copyWith(logLevel: value));
    Logger.root.warning("updated prefs: logLevel=$value");
  }

  Future<void> setSearchMode(TextSearchMode value) async {
    await updatePrefs(_prefs.copyWith(textSearchMode: value));
    Logger.root.info("updated prefs: textSearchMode=$value");
  }

  Future<void> setTodaySummaryMode(SummaryMode value) async {
    await updatePrefs(_prefs.copyWith(summaryMode: value));
    Logger.root.info("updated prefs: todaySummaryMode=$value");
  }

  Future<void> updatePrefs(AppPrefs newPrefs) async {
    // remember new data
    _prefs = newPrefs;
    // update logger
    Logger.root.level = newPrefs.logLevel.toLogging();
    // persist new preferences
    await PrefsIo.store(_prefs, _prefsFile);
    notifyListeners();
  }

  Future<void> clearPrefs() async {
    await _prefsFile.delete();
    _prefs = AppPrefs();
  }

  /// Get directory inside configured storage dir
  Future<Directory> storeSubdir([String subfolder = "export"]) async {
    final dir = Directory(p.join(_userStoreDir.path, subfolder));
    // ensure exists
    await dir.create(recursive: true);

    return dir;
  }

  /// convenience function for getting a event type color
  Color colorFor(EvtTypeRec? evtType) {
    return _evtTypeManager.colorFor(evtType, prefs.colorSpread);
  }
}
