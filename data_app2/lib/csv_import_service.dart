import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/csv_util.dart';
import 'package:data_app2/csv/evt_csv_adapter.dart';
import 'package:data_app2/csv/evt_type_csv_adapter.dart';
import 'package:data_app2/data/evt_draft.dart';
import 'package:data_app2/import/import_candidate_collection.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/util/process_state.dart';

/// For importing multiple CSV files.
class CsvImportService {
  final AppState _app;

  ProcessState<EvtImportSummary> state = Loading();

  CsvImportService(this._app);

  /// Load candidate files. NOTE: updates collection
  Future<void> load(ImportCandidateCollection collection) async {
    // First: types
    for (var cand in collection.evtTypeCands) {
      final recs = await _parseFile<EvtTypeRec>(cand.file, EvtTypeCsvAdapter());

      final idOverlapCount = recs
          .map((r) => r.id)
          .toSet()
          .intersection(await _app.db.eventTypes.allIds())
          .length;

      cand.summary = ImportCandidateSummary(recs, idOverlapCount);
    }

    // Second: events
    for (var cand in collection.evtCands) {
      final recs = await _parseFile<EvtDraft>(cand.file, EvtCsvAdapter());
      final idOverlapCount = recs
          .map((r) => r.id)
          .toSet()
          .intersection(await _app.db.events.allIds())
          .length;

      cand.summary = ImportCandidateSummary(recs, idOverlapCount);
    }
  }

  Future<List<T>> _parseFile<T>(File file, CsvAdapter<T> adapter) async {
    final lines = await file.readAsLines();
    final recs = adapter.parseRows(lines.skip(1));

    return recs;
  }
}
