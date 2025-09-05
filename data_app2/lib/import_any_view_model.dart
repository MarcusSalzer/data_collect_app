import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/csv_format.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/process_state.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';

class ImportAnyViewModel extends ChangeNotifier {
  String filePath;
  ProcessState<ImportableSummary> state = Loading();

  final AppState _app;

  List<EvtRec>? records;

  ImportAnyViewModel(this.filePath, this._app) {
    load();
  }

  /// Load file
  Future<void> load() async {
    await Future.delayed(Duration(milliseconds: 300));
    final file = File(filePath);
    final lines = await file.readAsLines();
    final header = lines[0];
    // try detect schema
    final match = SchemaRegistry.inferFromHeaderLine(header, RecordKind.event);
    // default error
    if (match == null) {
      state = Error(
          "Only event datasets supported for now. Expects header like:",
          examples: SchemaRegistry.allForKinds(
                  [RecordKind.event, RecordKind.eventType])
              .map(
                (li) => li.join(","),
              )
              .toList());
    } else if (match.kind == RecordKind.event) {
      // matches events header
      await prepareImportEvents(match, lines);
    } else if (match.kind == RecordKind.eventType) {
      // matches event-type header
      state = Error("only events implemented, no types now");
    } else {
      state = Error("match error $match");
    }

    notifyListeners();
  }

  /// read file and inspect data before importing
  prepareImportEvents(CsvSchemaFound match, Iterable<String> lines) async {
    final adapter =
        EventCsvAdapter(match.sep, match.schemaLevel, _app.evtTypeRepo);
    try {
      final recs = adapter.parseRows(lines.skip(1));
      final dbIds = await _app.db.allEventIds();
      final fileIds = recs.map((r) => r.id).toSet();
      final idOverlap = dbIds.intersection(fileIds);

      state = Ready(
        ImportableSummary.fromEvtRecs(recs)..idOverlapCount = idOverlap.length,
      );

      records = recs;
    } catch (e) {
      state = Error(e);
    }
  }

  Future<int> doImport() async {
    final recs = records;
    if (recs == null) {
      state = Error("No records");
      notifyListeners();
      return -1;
    }
    state = Loading();
    notifyListeners();

    await Future.delayed(Duration(milliseconds: 300));

    final c =
        await _app.db.importEventsDB(recs.map((r) => r.toIsar()).toList());

    state = Done();
    notifyListeners();
    return c;
  }
}
