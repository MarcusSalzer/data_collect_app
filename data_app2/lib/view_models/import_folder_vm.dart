import 'dart:io';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv_2/csv_row.dart';
import 'package:data_app2/csv_2/evt_csv.dart';
import 'package:data_app2/csv_2/evt_type_csv.dart';
import 'package:data_app2/import/import_candidate_collection.dart';
import 'package:data_app2/util/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

extension ImportOverlapPolicyUi on ImportOverlapPolicy {
  String get title => switch (this) {
    ImportOverlapPolicy.skip => 'Skip existing',
    ImportOverlapPolicy.overwrite => 'Overwrite existing',
    // ImportOverlapPolicy.reassignNew => 'New Ids',
  };

  String get description => switch (this) {
    ImportOverlapPolicy.skip => 'Records with IDs already in the database will not be imported.',
    ImportOverlapPolicy.overwrite => 'Imported records will replace existing records with the same ID.',
    // ImportOverlapPolicy.reassignNew =>
    //   'Imported records will be assigned new IDs to avoid conflicts.',
  };
}

class ImportResult {
  Set<int> newTypeIds;
  int evtCount;

  int get evtTypeCount => newTypeIds.length;

  ImportResult(this.newTypeIds, this.evtCount);
}

/// Handle folder import workflow:
/// - scan folder
/// - prepare data
/// - import to DB
///
/// User should confirm each step
class ImportFolderVm extends ChangeNotifier {
  ImportFolderVm(this.folder, this._app);

  final AppState _app;
  final Directory folder;

  // --- State ---
  final _candidates = ImportCandidateCollection(); // mutable collection
  final Map<CsvImportCandidate, List<CsvRow>> rowsPerCand = {};

  ImportStep _step = ImportStep.scanningFolder; // progress through steps
  String? _errorMsg;
  ImportResult? _result;
  ImportOverlapPolicy _overlapPolicy = ImportOverlapPolicy.skip; // default
  bool _showOverlapOptions = false; // showing a form

  // --- Get ---
  ImportStep get step => _step;
  String? get error => _errorMsg;
  ImportResult? get result => _result;
  ImportCandidateCollection get candidates => _candidates;
  ImportOverlapPolicy get overlapPolicy => _overlapPolicy;
  bool get showOverlapOptions => _showOverlapOptions;

  /// Step 1: scan folder for candidate files
  Future<void> scanFolder() async {
    _setStep(ImportStep.scanningFolder);

    try {
      _candidates.clear();

      // Find all files with .csv extension
      final files = folder.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.csv'));

      for (final file in files) {
        await candidates.addFile(file);
      }

      _setStep(ImportStep.confirmFiles);
    } on PathNotFoundException catch (e) {
      _fail("Could not find the directory '${e.path}'. (${e.osError})");
    } catch (e) {
      _fail(e.toString());
    }
  }

  /// Step 2: read the whole files and make in memory models
  Future<void> prepareCsvRows() async {
    _setStep(ImportStep.preparingModels);
    // First: types
    final nameCounts = <String, int>{};
    for (var cand in candidates.evtTypeCands) {
      final rows = EvtTypeCsvCodec().parseRows(await cand.file.readAsLines()).toList();

      // Ensure unique Event type names
      for (var rn in rows.map((r) => r.req("name"))) {
        nameCounts[rn] = (nameCounts[rn] ?? 0) + 1;
      }
      final duplicates = nameCounts.entries.where((e) => e.value > 1).map((e) => e.key).toList();
      if (duplicates.isNotEmpty) {
        throw FormatException("duplicate event names: ${duplicates.join(',')}");
      }

      // Store loaded rows
      rowsPerCand[cand] = rows;
    }

    // Second: events
    for (var cand in candidates.evtCands) {
      rowsPerCand[cand] = EvtCsvCodec(typMan: _app.evtTypeManager).parseRows(await cand.file.readAsLines()).toList();
    }

    try {
      _setStep(ImportStep.confirmImport);
    } catch (e) {
      _fail(e.toString());
    }
  }

  /// Step 3: Import to Database
  Future<void> importToDb() async {
    _setStep(ImportStep.importing);
    List<int> addedTypeIds = [];
    int evtImportCount = 0;

    try {
      // import types
      for (var cand in candidates.evtTypeCands) {
        if (rowsPerCand[cand] case List<CsvRow> rows) {
          final items = EvtTypeCsvCodec().decode(rows);

          // unique index might fail here
          addedTypeIds = await _app.db.eventTypes.createAllThrowEarly(items);
        }

        // switch (_overlapPolicy) {
        //   case ImportOverlapPolicy.skip:
        //     addedTypeIds = await _app.db.eventTypes.createAll(items);
        //     break;
        //   case ImportOverlapPolicy.overwrite:
        //     addedTypeIds = await _app.db.eventTypes.updateAll(items);
        //     break;
        // case ImportOverlapPolicy.reassignNew:
        //   throw UnimplementedError();
        // }
      }
      // refresh types
      _app.evtTypeManager.reloadFromModels(await _app.db.eventTypes.all());

      // import events
      for (var cand in candidates.evtCands) {
        if (rowsPerCand[cand] case List<CsvRow> rows) {
          final items = EvtCsvCodec(typMan: _app.evtTypeManager).decode(rows);

          // no unique-index, should be safe to do all at once.
          evtImportCount = (await _app.db.events.createAll(items)).length;
          // switch (_overlapPolicy) {
          //   case ImportOverlapPolicy.skip:
          //     evtImportCount = (await _app.db.events.putIfNewId(items)).length;
          //     break;
          //   case ImportOverlapPolicy.overwrite:
          //     evtImportCount = (await _app.db.events.updateAll(items)).length;
          //     break;
          // case ImportOverlapPolicy.reassignNew:
          //   throw UnimplementedError();
          // }
        }
      }

      _setStep(ImportStep.done);
    } on IsarError catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail(e.toString());
    }
    _result = ImportResult(addedTypeIds.toSet(), evtImportCount);
  }

  /// Update current step and notify listeners
  void _setStep(ImportStep step) {
    _step = step;
    notifyListeners();
  }

  /// Update step and error message, and notify listeners
  void _fail(String message) {
    _errorMsg = message;
    _step = ImportStep.error;
    notifyListeners();
  }

  void toggleOverlapOptions() {
    _showOverlapOptions = !_showOverlapOptions;
    notifyListeners();
  }

  void closeOverlapOptions() {
    _showOverlapOptions = false;
    notifyListeners();
  }

  /// Set how to handle overlaps in import
  void setOverlapPolicy(ImportOverlapPolicy? policy) {
    if (policy != null) _overlapPolicy = policy;
    notifyListeners();
  }
}
