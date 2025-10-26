import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/colors.dart';
import 'package:data_app2/enums.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
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
/// Store the time both in local and utc to avoid ambiguities when traveling or DST
@collection
class Event {
  Id id = Isar.autoIncrement;
  int typeId;

  // start and end times are optional
  @Index()
  int? startLocalMillis;
  int? startUtcMillis;
  @Index()
  int? endLocalMillis;
  int? endUtcMillis;

  Event({
    required this.typeId,
    this.startLocalMillis,
    this.startUtcMillis,
    this.endLocalMillis,
    this.endUtcMillis,
  });

  // factory Event.fromDateTimes(
  //     int typeId, DateTime? startLocal, DateTime? endLocal) {
  //   if (startLocal != null && startLocal.isUtc ||
  //       (endLocal != null && endLocal.isUtc)) {
  //     throw ArgumentError("Expects local datetimes");
  //   }
  //   return Event(
  //     typeId: typeId,
  //     startLocalMillis: startLocal?.toUtc().millisecondsSinceEpoch,
  //     startUtcMillis: startLocal?.millisecondsSinceEpoch,
  //     endLocalMillis: endLocal?.toUtc().millisecondsSinceEpoch,
  //     endUtcMillis: endLocal?.millisecondsSinceEpoch,
  //   );
  // }
}

/// A type of event
@collection
class EventType {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String name;
  @Enumerated(EnumType.ordinal)
  ColorKey color;
  int? categoryId;

  EventType(this.name, [this.color = ColorKey.base, this.categoryId]);
}

/// A type of event
@collection
class EventCategory {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String name;

  EventCategory(this.name);
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

  Future<List<EventType>> getEventTypes() async {
    final evtTypes = await _isar.txn(() async {
      return await _isar.eventTypes.where().findAll();
    });

    return evtTypes;
  }

  /// get all event id:s from db
  Future<Set<int>> allEventIds() async {
    return await _isar.txn(() async {
      return (await _isar.events.where().idProperty().findAll()).toSet();
    });
  }

  /// get all referenced typeId:s on events
  Future<Set<int>> allReferencedTypeIds() async {
    return await _isar.txn(() async {
      return (await _isar.events.where().typeIdProperty().findAll()).toSet();
    });
  }

  /// get all existing typeId:s
  Future<Set<int>> allTypeIds() async {
    return await _isar.txn(() async {
      return (await _isar.eventTypes.where().idProperty().findAll()).toSet();
    });
  }

  Future<EventType?> getEventType({int? id, String? name}) async {
    return await _isar.txn(() async {
      if (id != null) {
        return await _isar.eventTypes.get(id);
      } else if (name != null) {
        return await _isar.eventTypes.where().nameEqualTo(name).findFirst();
      }
      return null;
    });
  }

  /// Get if exists, otherwise make a new
  Future<EventType> getOrCreateEventType(String name) async {
    return await _isar.writeTxn(() async {
      final existing =
          await _isar.eventTypes.filter().nameEqualTo(name).findFirst();
      if (existing != null) {
        return existing;
      } else {
        final newType = EventType(name);
        await _isar.eventTypes.put(newType);
        return newType;
      }
    });
  }

  /// save or update EventType, returns id.
  Future<int> saveOrUpdateEventTypeByName(EvtTypeRec rec) async {
    return await _isar.writeTxn(() async {
      final existing =
          await _isar.eventTypes.where().nameEqualTo(rec.name).findFirst();
      if (existing != null) {
        // give id to update instead of create
        rec.id = existing.id;
      }
      return await _isar.eventTypes.put(rec.toIsar());
    });
  }

  /// create and save new EventType, with name and defaults
  Future<int> newEventType(String name) async {
    return await _isar.writeTxn(() async {
      return await _isar.eventTypes.put(EventType(name));
    });
  }

  /// create and save new EventType, with name and defaults
  Future<int?> newEventTypeWithId(int id, String name) async {
    return await _isar.writeTxn(() async {
      // skip if exists
      if (await _isar.eventTypes.where().idEqualTo(id).isNotEmpty()) {
        return null;
      }
      return await _isar.eventTypes.put(EventType(name)..id = id);
    });
  }

  Future<List<Event>> getAllEvents() async {
    return await _isar.txn(() async {
      return await _isar.events.where().findAll();
    });
  }

  Future<Event?> getOneEvent() async {
    return await _isar.txn(() async {
      return await _isar.events.where().anyId().findFirst();
    });
  }

  Future<int> countEvents() async {
    return await _isar.txn(() async {
      return await _isar.events.count();
    });
  }

  Future<int> countEventTypes() async {
    return await _isar.txn(() async {
      return await _isar.eventTypes.count();
    });
  }

  Future<bool> deleteEvent(int id) async {
    return await _isar.writeTxn(() async {
      return _isar.events.delete(id);
    });
  }

  /// Save a new or updated event
  ///
  /// returns: id.
  Future<int> putEvent(Event evt) async {
    return await _isar.writeTxn(() async {
      return _isar.events.put(evt);
    });
  }

  /// reverse chronological events
  Future<List<Event>> latestEvents(int? count) async {
    return await _isar.txn(() async {
      return _isar.events
          .where(sort: Sort.desc)
          .anyStartLocalMillis()
          .optional(count != null, (q) => q.limit(count!))
          .findAll();
    });
  }

  /// Save Events to database
  Future<int> importEventsDB(List<Event> data) async {
    final c = await _isar.writeTxn(() async {
      final ids = await _isar.events.putAll(data);
      return ids.length;
    });
    return c;
  }

  /// Save [EvtDrafts]s to database
  // Future<int> importEvtDraftsDB(List<EvtDraft> data) async {
  //   final c = await _isar.writeTxn(() async {
  //     final ids = await _isar.events.putAll(data);
  //     return ids.length;
  //   });
  //   return c;
  // }

  /// Delete all events
  Future<int> deleteAllEvents() async {
    final c = await _isar.events.count();

    await _isar.writeTxn(() async {
      _isar.events.clear();
    });

    return c;
  }

  /// Delete all event types
  Future<int> deleteAllEventTypes() async {
    final c = await _isar.eventTypes.count();

    await _isar.writeTxn(() async {
      _isar.eventTypes.clear();
    });

    return c;
  }

  Future<bool> deleteEventType(int id) async {
    return await _isar.writeTxn(() async {
      return _isar.eventTypes.delete(id);
    });
  }

  /// Get some events.
  Future<List<Event>> getEventsFilteredLocalTime({
    List<int>? typeIds,
    LocalDateTime? earliest,
    LocalDateTime? latest,
  }) async {
    final evts = await _isar.txn(() async {
      return _isar.events
          // sort reverse chrono
          .where(sort: Sort.desc)
          // optinally filter by time range
          .optional(
            earliest != null,
            (q) => q.startLocalMillisGreaterThan(
              earliest!.localMillis,
              include: true,
            ),
          )
          .filter()
          .optional(latest != null,
              (q) => q.endLocalMillisLessThan(latest!.localMillis))
          // optionally filter by evt type
          .optional(typeIds != null,
              (q) => q.anyOf(typeIds!, (q, int n) => q.typeIdEqualTo(n)))
          .findAll();
    });
    return evts;
  }

  /// Save a new tabular dataset NOTE: ONLY INT FOR NOW
  Future<void> saveUserTable(
      String name, List<String> colNames, TableFreq freq) async {
    // TODO actually define schema
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

/// Initialize DB connection
Future<Isar> initIsar() async {
  final docDir = await getApplicationDocumentsDirectory();
  final path = p.join(docDir.path, 'data_collect');
  // Ensure storage folder exists
  Directory(path).createSync();
  final isar = await Isar.open([
    PreferencesSchema,
    EventSchema,
    UserTableSchema,
    UserRowSchema,
    EventTypeSchema,
    EventCategorySchema
  ], directory: path);
  return isar;
}
