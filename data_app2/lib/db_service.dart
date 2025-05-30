import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/enums.dart';
import 'package:data_app2/io.dart';
import 'package:flutter/material.dart';
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
  // where to store data?
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

// USER-DEFINED TABULAR DATASETS

@collection
class UserTable {
  Id id = Isar.autoIncrement;
  String name;
  List<String> colNames;
  // the datatype for each column (enum for each column)
  @Enumerated(EnumType.ordinal)
  List<TabularType> schema;
  // optionally keep records at a fixed frequency
  @Enumerated(EnumType.ordinal)
  TableFreq frequency = TableFreq.free;

  UserTable(this.name, this.colNames, this.schema,
      {this.frequency = TableFreq.free});
}

@collection
class UserRow {
  Id? id;
  // what table does the record belong to?
  int tableId;
  DateTime timestamp;
  // values for each column, decode according to the Table's schema
  List<int?> values;

  UserRow(this.tableId, this.timestamp, this.values, {this.id});
}

class DBService {
  final Isar _isar;

  // TODO: remove this to encapsulate db use
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

  /// Save [EvtRec]s to database
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
          .optional(earliest != null,
              (q) => q.startGreaterThan(earliest, include: true))
          .optional(latest != null, (q) => q.startLessThan(latest))
          // optionally filter by name
          .optional(names != null,
              (q) => q.anyOf(names!, (q, String n) => q.nameEqualTo(n)))
          .findAll();
    });
    return evts;
  }

  /// Save a new tabular dataset NOTE: ONLY INT FOR NOW
  Future<void> saveUserTable(
      String name, List<String> colNames, TableFreq freq) async {
    final schema = List.filled(colNames.length, TabularType.int);
    final tableDef = UserTable(name, colNames, schema, frequency: freq);
    await _isar.writeTxn(() async {
      _isar.userTables.put(tableDef);
    });
  }

  /// Load all tabular datasets
  Future<List<UserTable>> loadUserTables() async {
    return await _isar.txn(() async {
      return _isar.userTables.where().anyId().findAll();
    });
  }

  Future<bool> deleteUserTable(int tableId) async {
    final didDelete = await _isar.writeTxn(() async {
      return await _isar.userTables.delete(tableId);
    });
    return didDelete;
  }

  /// Delete all records from a table
  Future<int> truncateTable(int tableId) async {
    final count = await _isar.writeTxn(() async {
      return await _isar.userRows.filter().tableIdEqualTo(tableId).deleteAll();
    });
    return count;
  }

  /// Save one record to table
  Future<int> saveTableRecord(
      int tableId, DateTime timestamp, List<int?> values, int? id) async {
    final row = UserRow(tableId, timestamp, values, id: id);

    final idPut = await _isar.writeTxn(() async {
      return await _isar.userRows.put(row);
    });
    return idPut;
  }

  Future<bool> deleteTableRecord(int tableId, int recordId) async {
    final didDel = await _isar.writeTxn(() async {
      return await _isar.userRows.delete(recordId);
    });
    return didDel;
  }

  Future<List<UserRow>> getAllRecords(int tableId) async {
    final recs = await _isar.txn(() async {
      return await _isar.userRows.filter().tableIdEqualTo(tableId).findAll();
    });
    return recs;
  }

  /// Get all record from a year/month, from all tables or one specific
  Future<List<UserRow>> getTableRecordsTime(
      {required int? table, required DateTime dt}) async {
    final recs = await _isar.txn(() async {
      return _isar.userRows
          .filter()
          .optional(
            table != null,
            (q) => q.tableIdEqualTo(table!),
          )
          .timestampEqualTo(dt)
          .findAll();
    });
    return recs;
  }

  /// Get all record from a year/month, from all tables or one specific
  Future<List<UserRow>> getTableRecordsPeriod({
    required int? table,
    required int year,
    int? month,
    int? day,
  }) async {
    final start = DateTime(year, month ?? 1, day ?? 1);
    DateTime end;
    if (month != null && day == null) {
      end = DateUtils.addMonthsToMonthDate(start, 1);
    } else if (day != null) {
      end = start.copyWith(day: start.day + 1);
    } else {
      // default on year
      end = start.copyWith(year: start.year + 1);
    }
    // print("range: $start -> $end");

    final recs = await _isar.txn(() async {
      _isar.userRows
          .filter()
          .optional(
            table != null,
            (q) => q.tableIdEqualTo(table!),
          )
          .optional(month != null,
              (q) => q.timestampBetween(start, end, includeLower: true))
          .findAll();
    });
    return recs;
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
  final isar = await Isar.open(
      [PreferencesSchema, EventSchema, UserTableSchema, UserRowSchema],
      directory: path);
  return isar;
}
