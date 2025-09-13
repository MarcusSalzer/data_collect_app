import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/csv_simple.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/process_state.dart';
import 'package:flutter/material.dart';

class ImportAnyViewModel extends ChangeNotifier {
  String filePath;
  ProcessState<ImportableSummary> state = Loading();

  final AppState _app;
  final EvtSimpleCsvAdapter adapter = EvtSimpleCsvAdapter();

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
        examples: [
          "Expected: ${adapter.header}",
          "Got     : $header",
        ],
      );
    } else {
      // matches events header
      await prepareImportEvents(lines);
    }

    notifyListeners();
  }

  /// read file and inspect data before importing
  Future<void> prepareImportEvents(Iterable<String> lines) async {
    try {
      final recs = adapter.parseRows(lines.skip(1));
      final dbIds = await _app.db.allEventIds();
      final fileIds = recs.map((r) => r.id).toSet();
      final idOverlap = dbIds.intersection(fileIds);

      state = Ready(
        ImportableSummary.fromEvtDrafts(recs)
          ..idOverlapCount = idOverlap.length,
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

    await Future.delayed(Duration(milliseconds: 300));
    int c;
    try {
      // resolve all event types
      final evts = await Future.wait(
        recs.map(
          (r) async => r.toIsar(
            await _app.evtTypeRepo.resolveOrCreate(name: r.typeName),
          ),
        ),
      );
      c = await _app.db.importEventsDB(evts);

      state = Done();
    } catch (e) {
      c = -1;
      state = Error(e);
    }
    notifyListeners();
    return c;
  }
}
