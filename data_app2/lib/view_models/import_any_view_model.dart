import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/evt_csv_adapter.dart';
import 'package:data_app2/data/evt_draft.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/util/process_state.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// NOTE: Moving parts to CsvImportService
class ImportAnyViewModel extends ChangeNotifier {
  String filePath;
  ProcessState<EvtImportSummary> state = Loading();

  final AppState _app;
  final EvtCsvAdapter adapter = EvtCsvAdapter();

  List<EvtDraft>? evtDrafts;

  ImportAnyViewModel(this.filePath, this._app) {
    load();
  }

  /// Load file
  Future<void> load() async {
    await Future.delayed(Duration(milliseconds: 300));
    final file = File(filePath);
    final lines = await file.readAsLines();
    final header = lines[0];
    // default error
    if (header != adapter.header) {
      state = Error(
        "Unsupported header:",
        examples: ["Expected: ${adapter.header}", "Got     : $header"],
      );
    } else {
      // matches events header
      await _prepareImportEvents(lines);
    }

    notifyListeners();
  }

  /// read file and inspect data before importing
  Future<void> _prepareImportEvents(Iterable<String> lines) async {
    try {
      final recs = adapter.parseRows(lines.skip(1));
      final evtIdsDb = await _app.db.events.allIds();
      final evtIdsFile = recs.map((r) => r.id).toSet();
      final idOverlap = evtIdsDb.intersection(evtIdsFile);

      state = Ready(
        EvtImportSummary.fromEvtDrafts(recs)..idOverlapCount = idOverlap.length,
      );

      evtDrafts = recs;
    } catch (e) {
      state = Error(e);
    }
    notifyListeners();
  }

  Future<int> doImport() async {
    final recs = evtDrafts;
    if (recs == null) {
      state = Error("No records");
      notifyListeners();
      return -1;
    }
    state = Loading();
    notifyListeners();

    await Future.delayed(Duration(milliseconds: 100));
    int c;
    try {
      // resolve all event types
      final evts = await Future.wait(
        recs.map(
          (r) async => r.toIsar(
            await _app.evtTypeManager.resolveOrCreate(name: r.typeName),
          ),
        ),
      );
      c = await _app.db.events.putAll(evts);

      state = Done();
    } catch (e) {
      c = -1;
      state = Error(e);
    }
    notifyListeners();

    Logger.root.info("Imported $c events");
    return c;
  }
}
