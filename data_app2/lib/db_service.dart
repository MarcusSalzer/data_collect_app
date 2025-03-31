import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// important: this file will contain Isar's generated code.
part 'db_service.g.dart';

const eventsCsvHeader = "id, name, start, end";

/// A singleton Isar object holding app prefs
@collection
class Preferences {
  Id id = 0; // a single instance.
  bool darkMode = false;
  // input normalization preferences (applies globally for now)
  bool normalizeStrip = false;
  bool normalizeCase = false;
  // where to store data
  // TODO String? dataPath;
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
    final prefs = Preferences()
      ..darkMode = app.isDarkMode
      ..normalizeStrip = app.normStrip
      ..normalizeCase = app.normCase;
    await _isar.writeTxn(() async {
      _isar.preferences.put(prefs);
    });
  }

  /// Load app preferences
  Future<void> loadPrefs(AppState app) async {
    final prefs = await _isar.preferences.get(0);

    if (prefs != null) {
      app.setDarkMode(prefs.darkMode);
      app.setNormCase(prefs.normalizeCase);
      app.setNormStrip(prefs.normalizeStrip);
    }
  }

  /// Export events as CSV
  Future<int> exportEvents() async {
    final events = await _isar.events.where().findAll();

    final nEvt = events.length;
    final lines = events.map((evt) {
      final nameSafe = evt.name.replaceAll(",", ";");
      return "${evt.id}, $nameSafe, ${evt.start?.toIso8601String()}, ${evt.end?.toIso8601String()}";
    });

    final csvContent = "$eventsCsvHeader\n${lines.join('\n')}";

    final dir = await defaultStoreDir();
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final n = DateTime.now();
    final file = File(
      p.join(dir.path,
          'events_${n.year}-${n.month}-${n.day}-${n.hour}-${n.minute}.csv'),
    );
    file.writeAsString(csvContent);
    return nEvt;
  }

  /// Load events from CSV file.
  Future<int> importEventsCSV(String path) async {
    final file = File(path);

    final lines = await file.readAsLines();
    if (lines[0] != eventsCsvHeader) {
      // TODO catch this nicely!
      throw Exception("wrong CSV header: ${lines[0]}");
    }

    // parse text
    final data = [];
    for (var line in lines.skip(1)) {
      final fields = line.split(",");
      // print(fields[2]);
      final r = (
        name: fields[1],
        start: DateTime.tryParse(fields[2].trim()),
        end: DateTime.tryParse(fields[3].trim()),
      );
      data.add(r);
    }

    final c = await _isar.writeTxn(() async {
      final ids = await _isar.events.putAll(
        data
            .map(
              (r) => Event(r.name, start: r.start, end: r.end),
            )
            .toList(),
      );
      return ids.length;
    });
    return c;
  }

  /// Delete all events...
  Future<int> deleteAll() async {
    final c = await _isar.events.count();

    _isar.writeTxn(() async {
      _isar.events.clear();
    });

    return c;
  }
}

Future<Directory> defaultStoreDir() async {
  if (Platform.isAndroid) {
    return Directory('/storage/emulated/0/Documents/data_app');
  } else {
    return getApplicationDocumentsDirectory();
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
