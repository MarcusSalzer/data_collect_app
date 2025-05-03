import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/io.dart';
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
  // input normalization preferences (applies globally for now)
  bool normalizeStrip = false;
  bool normalizeCase = false;
  // where to store data
  // TODO String? dataPath;
}

/// A timed event
@collection
class Event {
  Id id = Isar.autoIncrement;
  String name;
  // start and end times are optional
  DateTime? start;
  DateTime? end;

  Event(this.name, {this.start, this.end});
}

/// A type of event
@collection
class EventType {
  Id id = Isar.autoIncrement;
  String name;
  String? category;

  EventType(this.name);
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
  Future<Preferences?> loadPrefs() async {
    final prefs = await _isar.preferences.get(0);
    return prefs;
  }

  /// Export events as CSV
  Future<int> exportEvents() async {
    final events = await _isar.events.where().findAll();

    final nEvt = events.length;
    final lines = events.map((evt) {
      final nameSafe = evt.name.replaceAll(",", ";");
      return "${evt.id}, $nameSafe, ${evt.start?.toIso8601String()}, ${evt.end?.toIso8601String()}";
    });
    const eventsCsvHeader = "id,name,start,end";
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

  ///
  Future<int> importEventsDB(Iterable<EvtRec> data) async {
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
  Future<int> deleteAllEvents() async {
    final c = await _isar.events.count();

    _isar.writeTxn(() async {
      _isar.events.clear();
    });

    return c;
  }

  /// Get some events. Note that this is independent of the EventModel
  Future<List<Event>> getEventsFiltered({
    List<String>? names,
    DateTime? earliest,
    DateTime? latest,
  }) async {
    final evts = await _isar.txn(() async {
      return _isar.events
          .filter()
          // optinally filter by time range
          .optional(earliest != null, (q) => q.startGreaterThan(earliest))
          .optional(latest != null, (q) => q.startLessThan(latest))
          // optionally filter by name
          .optional(names != null,
              (q) => q.anyOf(names!, (q, String n) => q.nameEqualTo(n)))
          .findAll();
    });
    return evts;
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
