import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/csv_improved.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/import/import_candidate_collection.dart';
import 'package:data_app2/io.dart';
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
      final recs = EvtTypeCsvDecoding.decodeRecs(await cand.file.readAsLines()).toList();

      final idOverlapCount = recs.map((r) => r.id).toSet().intersection(await _app.db.eventTypes.allIds()).length;

      cand.summary = ImportCandidateSummary(recs, idOverlapCount);
    }

    // Second: events
    for (var cand in collection.evtCands) {
      final recs = await EvtCsvDecoding.decodeRecs(await cand.file.readAsLines(), _app.evtTypeManager).toList();
      final idOverlapCount = recs.map((r) => r.id).toSet().intersection(await _app.db.events.allIds()).length;

      cand.summary = ImportCandidateSummary<EvtRec>(recs, idOverlapCount);
    }
  }
}
