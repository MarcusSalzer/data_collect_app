import 'dart:io';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/csv/evt_cat_csv.dart';
import 'package:data_app2/csv/evt_csv.dart';
import 'package:data_app2/csv/evt_type_csv.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/import/import_candidate_collection.dart';
import 'package:data_app2/util/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:logging/logging.dart';

extension ImportOverlapPolicyUi on ImportOverlapPolicy {
  String get title => switch (this) {
    ImportOverlapPolicy.fail => 'Fail if existing',
    ImportOverlapPolicy.skip => 'Skip existing',
    // ImportOverlapPolicy.overwrite => 'Overwrite existing',
    // ImportOverlapPolicy.reassignNew => 'New Ids',
  };

  String get description => switch (this) {
    ImportOverlapPolicy.fail => 'Cancel if trying to import existing',
    ImportOverlapPolicy.skip => 'Records with IDs already in the database will not be imported.',
    // ImportOverlapPolicy.overwrite => 'Imported records will replace existing records with the same ID.',
    // ImportOverlapPolicy.reassignNew =>
    //   'Imported records will be assigned new IDs to avoid conflicts.',
  };
}

class ImportResult {
  Set<int> newTypeIds;
  Set<int> newCatIds;
  int evtCount;
  int skippedTypeCount;

  int get evtTypeCount => newTypeIds.length;

  ImportResult(this.newCatIds, this.newTypeIds, this.evtCount, this.skippedTypeCount);
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
  ImportOverlapPolicy _overlapPolicy = ImportOverlapPolicy.fail; // default
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
        await _candidates.addFile(file);
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
    try {
      // --- CATS ---
      for (var cand in candidates.evtCatCands) {
        final rows = parseRows(await cand.file.readAsLines()).toList();
        // Store loaded rows
        rowsPerCand[cand] = rows;
      }

      // --- TYPES ---
      final typeNameCounts = <String, int>{};
      for (var cand in candidates.evtTypeCands) {
        final rows = parseRows(await cand.file.readAsLines()).toList();

        // Ensure unique Event type names
        for (var rn in rows.map((r) => r.req("name"))) {
          typeNameCounts[rn] = (typeNameCounts[rn] ?? 0) + 1;
        }
        final duplicates = typeNameCounts.entries.where((e) => e.value > 1).map((e) => e.key).toList();
        if (duplicates.isNotEmpty) {
          throw StateError("duplicate event names: ${duplicates.join(',')}");
        }

        // Store loaded rows
        rowsPerCand[cand] = rows;
      }

      // --- EVENTS ---
      for (var cand in candidates.evtCands) {
        rowsPerCand[cand] = parseRows(await cand.file.readAsLines()).toList();
      }

      _setStep(ImportStep.confirmImport);
    } catch (e) {
      _fail(e.toString());
    }
  }

  /// Step 3: Import to Database
  /// NOTE: imported in reference order: 1. cats <- 2. types <- 3. events
  Future<void> importToDb() async {
    _setStep(ImportStep.importing);
    List<int> addedTypeIds = [];
    List<EvtCatRec> newCats = [];
    int evtImportCount = 0;
    int skippedTypeCount = 0;

    try {
      // --- import CATEGORIES ---
      for (var cand in candidates.evtCatCands) {
        if (rowsPerCand[cand] case List<CsvRow> rows) {
          Logger.root.fine("importing ${rows.length} cats...");
          final items = EvtCatCsvCodec().decode(rows).toList();

          final nSkip = await _app.db.evtCats.createIfPossible(items);
          Logger.root.fine("skipped $nSkip cats.");
        }
      }
      // cache cats to resolve when importing types
      Logger.root.fine("loading all cats...");
      final allCats = await _app.db.evtCats.all();
      Logger.root.fine("reloading cache with ${allCats.length} categories...");
      _app.evtTypeManager.reloadFromModels(null, allCats);

      // --- import TYPES ---
      for (var cand in candidates.evtTypeCands) {
        if (rowsPerCand[cand] case List<CsvRow> rows) {
          Logger.root.fine("importing ${rows.length} types...");

          final items = EvtTypeCsvCodec.fromTypeManager(_app.evtTypeManager).decode(rows);

          switch (_overlapPolicy) {
            case ImportOverlapPolicy.fail:
              // unique index might fail here
              addedTypeIds.addAll(await _app.db.evtTypes.createAllThrowEarly(items));
              break;
            case ImportOverlapPolicy.skip:
              throw UnimplementedError("Idk, doesnt work now");
          }
        }
      }
      // refresh types and categories
      _app.evtTypeManager.reloadFromModels(await _app.db.evtTypes.all(), null);

      // import events
      for (var cand in candidates.evtCands) {
        if (rowsPerCand[cand] case List<CsvRow> rows) {
          Logger.root.fine("importing ${rows.length} evts...");

          final items = EvtCsvCodec(typMan: _app.evtTypeManager).decode(rows);
          // no unique-index, should be safe to do all at once.
          evtImportCount = (await _app.db.evts.createAll(items)).length;
        }
      }

      _setStep(ImportStep.done);
    } on IsarError catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail(e.toString());
    }
    _result = ImportResult(newCats.map((r) => r.id).toSet(), addedTypeIds.toSet(), evtImportCount, skippedTypeCount);
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
