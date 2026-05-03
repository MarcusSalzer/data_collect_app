// Keep current settings in memory, for convenient access

import 'dart:io';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/today_summary_data.dart';
import 'package:data_app2/location_manager.dart';
import 'package:data_app2/prefs_io.dart';
import 'package:data_app2/style.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/evt_type_manager.dart';
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
  final LocationManager _locationManager;

  /// A user accessible directory for data
  Directory get userStoreDir => _userStoreDir;

  /// All preferences
  AppPrefs get prefs => _prefs;
  bool get autoLowerCase => _prefs.autoLowerCase;
  LogLevel get logLevel => _prefs.logLevel;
  TextSearchMode get textSearchMode => _prefs.textSearchMode;

  // get db instance & event types
  DBService get db => _db;
  File get prefsFile => _prefsFile;

  /// Get the singleton type manager
  EvtTypeManagerPersist get evtTypeManager => _evtTypeManager;

  /// Get the singleton location manager
  LocationManager get locationManager => _locationManager;

  // keep track of today summary
  TodaySummaryDataByType? todaySummary;

  final File _prefsFile;

  AppState(this._db, this._prefs, this._userStoreDir, this._prefsFile)
    : _evtTypeManager = EvtTypeManagerPersist(_db),
      _locationManager = LocationManager();

  /// Perform needed asynchronous initialization
  Future<void> init() async {
    // event types and categories
    // Fill the cache
    final (t, c) = await _db.allTypesAndCats();
    _evtTypeManager.reloadFromModels(t, c);

    // check dangling types
    _db.danglingTypeRefs().then((d) {
      final count = d.length;
      final msg = "has $count dangling type-refs";
      if (count > 0) {
        Logger.root.warning(msg);
      }
      Logger.root.info(msg);
    });
    // locations
    final locs = await _db.locations.all();
    _locationManager.reloadFromModels(locs);
  }

  Future<void> reloadLocations() async {
    final locs = await _db.locations.all();
    locationManager.reloadFromModels(locs);
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
    if (await _prefsFile.exists()) {
      await _prefsFile.delete();
    }
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
