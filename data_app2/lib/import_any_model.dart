import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/enums.dart';
import 'package:data_app2/extensions.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';

class ImportAnyModel extends ChangeNotifier {
  String filePath;
  String? error;
  ImportMode? mode;
  ImportState state = ImportState.loading;

  final AppState _app;

  ImportableSummary? summary;
  Iterable<EvtRec>? records;

  ImportAnyModel(this.filePath, this._app);

  /// Load file
  Future<void> load() async {
    await Future.delayed(Duration(seconds: 1));
    final file = File(filePath);
    final lines = await file.readAsLines();
    final header = lines[0];
    if (eventsCsvHeader.equalsIgnoreSpace(header)) {
      // matches events-header
      mode = ImportMode.event;
      try {
        final (recs, summ) = await prepareImportEvts(lines.skip(1), _app);
        summary = summ;
        records = recs;
      } on FormatException catch (e) {
        error = e.message;
      } catch (e) {
        error = "unknown error";
      }
    } else {
      mode = ImportMode.tabular;
      // parse column names
      final colNames = header.split(",").map((s) => s.trim()).toList();

      // maybe matches a user table?
      final tableDefs = await _app.db.loadUserTables();
      final table = tableDefs.where((t) => t.colNames == colNames).firstOrNull;

      if (table == null) {
        error = "No matching table with header: '$header'";
        notifyListeners();

        return;
      }
      // print("found table: ${table.name}");

      // parse file and make summary
    }
    state = ImportState.ready;

    notifyListeners();
  }

  Future<int> doImport() async {
    final recs = records;
    if (recs == null) {
      state == ImportState.error;
      error == "no records";
      notifyListeners();
      return -1;
    }
    state = ImportState.loading;
    notifyListeners();

    await Future.delayed(Duration(seconds: 1));

    final c = await _app.db.importEventsDB(recs);

    state = ImportState.done;
    notifyListeners();
    return c;
  }
}
