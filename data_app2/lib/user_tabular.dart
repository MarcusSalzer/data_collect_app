// Allow the user to define their own tabular datasets,
// initially, only integers

import 'package:data_app2/db_service.dart';
import 'package:data_app2/enums.dart';
import 'package:data_app2/extensions.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/io.dart';
import 'package:flutter/material.dart';

class ColumnDef {
  final String name;
  final TabularType dtype;

  ColumnDef(this.name, this.dtype);

  decode(int? n) {
    if (n == null) {
      return null;
    }
    switch (dtype) {
      case TabularType.int:
        return n;
      case TabularType.cat:
        return "cat $n";
    }
  }

  encode(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is! int) {
      throw Exception("Expects INTS for now");
    }
    return value;
  }

  @override
  String toString() {
    return "Col($name, ${dtype.name})";
  }

  /// parse as appropriate dtype. empty string becomes null
  dynamic parse(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    switch (dtype) {
      case TabularType.int:
        return int.parse(value);
      case TabularType.cat:
        return value; // NOTE
    }
  }
}

/// In-memory representation of one table row
class TableRecord {
  int? id;
  DateTime timestamp;
  Map<String, dynamic> data;

  TableRecord(this.id, this.timestamp, {this.data = const {}});

  @override
  String toString() {
    return "record $id: ${data.values.join(', ')}";
  }

  /// CSV row of data record
  String toCsvRow() {
    final dataStr = data.values.join(", ");
    return "$id, ${timestamp.toIso8601String()}, $dataStr";
  }
}

/// info and conversions for a user defined table
class TableProcessor extends ChangeNotifier {
  final DBService _db;
  final int tableId;
  final String name;
  final List<ColumnDef> columns;
  final TableFreq freq;

  Future<void>? _initFuture;
  Future<void>? get initFuture => _initFuture;

  int get nColumns => columns.length;
  Iterable<TabularType> get dtypes => columns.map((c) => c.dtype);

  /// To keep an in memory data copy
  final List<TableRecord> _data = [];
  List<TableRecord> get data => _data;

  TableProcessor(this._db, this.tableId, this.name, this.columns, this.freq);

  Future<void> init() async {
    _initFuture = _initializeData(); // Set the future that the UI will track

    await _initFuture;
    notifyListeners(); // Notify UI to update once data is loaded
  }

  Future<void> _initializeData() async {
    _data.clear();
    final records = await _db.getAllRecords(tableId);
    _data.addAll(records.map((r) => decodeRow(r)));
  }

  /// Decode a record from database
  TableRecord decodeRow(UserRow row) {
    final data = <String, dynamic>{};
    for (var (i, dbVal) in row.values.indexed) {
      if (i >= columns.length) {
        break;
      }
      final col = columns[i];
      data[col.name] = col.decode(dbVal);
    }
    return TableRecord(row.id, row.timestamp, data: data);
  }

  /// Current datetime, to the precision of the table
  DateTime now() {
    final dt = DateTime.now();
    switch (freq) {
      case TableFreq.free:
        return dt;
      case TableFreq.day:
        return dt.startOfDay;
      case TableFreq.week:
        // Most recent monday
        return dt.startOfweek;
    }
  }

  /// Make an empty record for the table, or load an old match.
  Future<TableRecord> findByTimeOrNew() async {
    final nowLocal = now();
    if (freq != TableFreq.free) {
      final existing =
          await _db.getTableRecordsTime(table: tableId, dt: nowLocal);
      if (existing.isNotEmpty) {
        final rec = decodeRow(existing.first);
        return rec;
      }
    }
    return TableRecord(null, nowLocal);
  }

  /// Encode a record to save
  Future<void> save(TableRecord rec) async {
    final isNew = rec.id == null;
    final values = List<int?>.filled(nColumns, null);
    for (var (i, col) in columns.indexed) {
      values[i] = col.encode(rec.data[col.name]);
    }
    final newId =
        await _db.saveTableRecord(tableId, rec.timestamp, values, rec.id);
    if (isNew) {
      rec.id = newId;
      _data.add(rec);
    }
    notifyListeners();
  }

  /// delete a record
  Future<bool> delete(TableRecord rec) async {
    final recId = rec.id;
    if (recId == null) {
      return false;
    }

    final deleted = await _db.deleteTableRecord(tableId, recId);
    if (deleted) {
      _data.remove(rec);
      notifyListeners();
    }
    return deleted;
  }

  /// delete all data of the table
  Future<int> truncate() async {
    final count = await _db.truncateTable(tableId);
    // clear in-memory list
    _data.clear();

    notifyListeners();
    return count;
  }

  @override
  String toString() {
    return "Table($name): $columns";
  }

  String csvHeader({bool withSchema = false}) {
    if (withSchema) {
      return "id, time, ${columns.map((c) => "${c.name}[${c.dtype.name}]").join(", ")}";
    } else {
      return "id, time, ${columns.map((c) => c.name).join(", ")}";
    }
  }

  Future<void> exportCsv({bool withSchema = false}) async {
    final csvContent =
        tableRecordsToCsv(_data, csvHeader(withSchema: withSchema));
    final fileName = "${name}_${Fmt.dtSecond(DateTime.now())}";
    exportFile(fileName, csvContent);
  }
}

/// Manage user defined tables
class TableManager extends ChangeNotifier {
  final DBService _db;

  final List<TableProcessor> _tables = [];

  Future<void>? _initFuture;

  TableManager(this._db); // to know when tables are loaded

  List<TableProcessor> get tableProcessors => List.unmodifiable(_tables);
  List<String> get tableNames => List.unmodifiable(_tables.map((t) => t.name));
  Future<void>? get initFuture => _initFuture;

  // Called when the model is first created
  Future<void> init() async {
    _initFuture = _initializeData(); // Set the future that the UI will track

    await _initFuture;
    notifyListeners(); // Notify UI to update once data is loaded
  }

  Future<void> _initializeData() async {
    _tables.clear();
    final tableDefs = await _db.loadUserTables();

    /// create a TabularProcessor from each loaded table definition
    _tables.addAll(tableDefs.map((t) {
      final cols = List.generate(
        t.colNames.length,
        (i) {
          return ColumnDef(t.colNames[i], t.schema[i]);
        },
        growable: false,
      );
      return TableProcessor(_db, t.id, t.name, cols, t.frequency);
    }));
  }

  newTable(String tableName, List<String> colNames, TableFreq freq) async {
    await _db.saveUserTable(tableName, colNames, freq);
    init();
  }

  Future<bool> deleteTable(TableProcessor table) async {
    // delete all table data
    await table.truncate();
    // dispose ChangeNotifier
    table.dispose();
    // delete from DB
    final didDelete = await _db.deleteUserTable(table.tableId);
    if (!didDelete) return false;
    // remove from tables-list
    final didRemove = _tables.remove(table);
    notifyListeners();
    return didRemove;
  }
}
