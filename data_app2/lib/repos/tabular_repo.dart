import 'package:data_app2/util/enums.dart';
import 'package:data_app2/isar_models.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';

class TabularRepo {
  final Isar _isar;

  TabularRepo(this._isar);

  /// Save a new tabular dataset NOTE: ONLY INT FOR NOW
  Future<void> saveUserTable(
    String name,
    List<String> colNames,
    TableFreq freq,
  ) async {
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
    int tableId,
    DateTime timestamp,
    List<int?> values,
    int? id,
  ) async {
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
  Future<List<UserRow>> getTableRecordsTime({
    required int? table,
    required DateTime dt,
  }) async {
    final recs = await _isar.txn(() async {
      return _isar.userRows
          .filter()
          .optional(table != null, (q) => q.tableIdEqualTo(table!))
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
          .optional(table != null, (q) => q.tableIdEqualTo(table!))
          .optional(
            month != null,
            (q) => q.timestampBetween(start, end, includeLower: true),
          )
          .findAll();
    });
    return recs;
  }
}
