import 'dart:io';

import 'package:datacollectv2/app_state.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// important: this file will contain Isar's generated code.
part 'db_service.g.dart';

/// A singleton Isar object holding app prefs
@collection
class Preferences {
  Id id = 0; // a single instance.
  bool darkMode = false;
}

@collection
class Event {
  Id id = Isar.autoIncrement;
  String name;
  // start and end times are optional
  DateTime? start;
  DateTime? end;

  Event(this.name, {this.start, this.end});
}

class DBService {
  final Isar _isar;
  Isar get isar => _isar;

  DBService(this._isar);

  /// Save app preferences
  Future<void> updatePrefs(AppState app) async {
    await _isar.writeTxn(() async {
      _isar.preferences.put(Preferences()..darkMode = app.isDarkMode());
    });
  }

  /// Load app preferences
  Future<void> loadPrefs(AppState app) async {
    final prefs = await _isar.preferences.get(0);

    if (prefs != null) {
      app.setDarkMode(prefs.darkMode);
    }
  }
}

/// Initialize DB connection
Future<Isar> initIsar() async {
  final docDir = await getApplicationDocumentsDirectory();
  final path = p.join(docDir.path, 'data_collect');
  // Ensure storage folder exists
  Directory(path).createSync();
  final isar =
      await Isar.open([PreferencesSchema, EventSchema], directory: path);
  return isar;
}
