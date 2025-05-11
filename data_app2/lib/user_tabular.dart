// Allow the user to define their own tabular datasets,
// initially, only integers

import 'package:data_app2/db_service.dart';
import 'package:flutter/material.dart';

/// info and conversions for a user defined table
class TabularProcessor {
  final int id;
  final String name;
  // TODO SCHEMA
  TabularProcessor(this.id, this.name);

  /// Decode a record from database
  decodeRow(UserRow row) {}

  /// Encode a record to save
  encodeRow(UserRow row) {}
}

/// Manage user defined tables
class TabularModel extends ChangeNotifier {
  final DBService _dbService;

  final List<TabularProcessor> _tables = [];

  Future<void>? _initFuture;

  TabularModel(this._dbService); // to know when tables are loaded

  List<TabularProcessor> get tableProcessors => List.unmodifiable(_tables);
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
    final tableDefs = await _dbService.loadUserTables();

    /// create a TabularProcessor from each loaded table definition
    _tables.addAll(tableDefs.map(
      (t) => TabularProcessor(t.id, t.name),
    ));
  }

  newTable(String tableName, List<String> colNames) async {
    print("saving table: $tableName with columns ${colNames.join(",")}");
    await _dbService.saveUserTable(tableName, colNames);
    init();
  }
}
