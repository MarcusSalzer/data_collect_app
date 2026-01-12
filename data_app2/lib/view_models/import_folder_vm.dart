import 'dart:io';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv_import_service.dart';
import 'package:data_app2/import/import_candidate_collection.dart';
import 'package:flutter/foundation.dart';

enum ImportStep {
  scanningFolder,
  confirmFiles,
  preparingModels,
  confirmImport,
  importing,
  done,
  error,
}

/// How to import data, when its id is already in the DB
enum ImportOverlapPolicy {
  skip,
  overwrite,
  // reassignNew, // make new ids
}

extension ImportOverlapPolicyUi on ImportOverlapPolicy {
  String get title => switch (this) {
    ImportOverlapPolicy.skip => 'Skip existing',
    ImportOverlapPolicy.overwrite => 'Overwrite existing',
    // ImportOverlapPolicy.reassignNew => 'New Ids',
  };

  String get description => switch (this) {
    ImportOverlapPolicy.skip =>
      'Records with IDs already in the database will not be imported.',
    ImportOverlapPolicy.overwrite =>
      'Imported records will replace existing records with the same ID.',
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
  ImportFolderVm(this.folder, this._app) : service = CsvImportService(_app) {
    scanFolder();
  }

  final AppState _app;
  final Directory folder;
  final CsvImportService service;

  // --- State ---
  final _candidates = ImportCandidateCollection(); // mutable collection
  ImportStep _step = ImportStep.scanningFolder; // progress through steps
  String? _error;
  ImportResult? _result;
  ImportOverlapPolicy _overlapPolicy = ImportOverlapPolicy.skip; // default
  bool _showOverlapOptions = false; // showing a form

  // --- Get ---
  ImportStep get step => _step;
  String? get error => _error;
  ImportResult? get result => _result;
  ImportCandidateCollection get candidates => _candidates;
  ImportOverlapPolicy get overlapPolicy => _overlapPolicy;
  bool get showOverlapOptions => _showOverlapOptions;

  /// Step 1: scan folder for candidate files
  Future<void> scanFolder() async {
    _setStep(ImportStep.scanningFolder);

    await Future.delayed(Duration(milliseconds: 100));

    try {
      _candidates.clear();

      // Find all files with .csv extension
      final files = folder.listSync().whereType<File>().where(
        (f) => f.path.toLowerCase().endsWith('.csv'),
      );

      for (final file in files) {
        await candidates.addFile(file);
      }

      _setStep(ImportStep.confirmFiles);
    } catch (e) {
      _fail(e.toString());
    }
  }

  /// Step 2: read the whole files and make in memory models
  Future<void> prepareDomainModels() async {
    _setStep(ImportStep.preparingModels);

    await service.load(candidates);

    _setStep(ImportStep.confirmImport);
  }

  /// Step 3: Import to Ddatabase
  Future<void> importToDb() async {
    _setStep(ImportStep.importing);
    List<int> addedTypeIds = [];
    int evtImportCount = 0;

    try {
      await Future.delayed(const Duration(milliseconds: 200));
      // import types
      for (var c in candidates.evtTypeCands) {
        if (c.summary case ImportCandidateSummary(:final records)) {
          switch (_overlapPolicy) {
            case ImportOverlapPolicy.skip:
              addedTypeIds = await _app.db.eventTypes.putIfNewId(records);
              break;
            case ImportOverlapPolicy.overwrite:
              addedTypeIds = await _app.db.eventTypes.putAll(records);
              break;
            // case ImportOverlapPolicy.reassignNew:
            //   // TODO: Handle this case.
            //   throw UnimplementedError();
          }
        }
      }
      // refresh types
      _app.evtTypeManager.reloadFromIsar(await _app.db.eventTypes.all());

      // import events
      for (var c in candidates.evtCands) {
        if (c.summary case ImportCandidateSummary(:final records)) {
          // resolve all event types
          final evts = await Future.wait(
            records.map(
              (r) async => r.toIsar(
                await _app.evtTypeManager.resolveOrCreate(name: r.typeName),
              ),
            ),
          );

          switch (_overlapPolicy) {
            case ImportOverlapPolicy.skip:
              evtImportCount = await _app.db.events.putIfNewId(evts);
              break;
            case ImportOverlapPolicy.overwrite:
              evtImportCount = await _app.db.events.putAll(evts);
              break;
            // case ImportOverlapPolicy.reassignNew:
            //   // TODO: Handle this case.
            //   throw UnimplementedError();
          }
        }
      }

      _setStep(ImportStep.done);
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
    _error = message;
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
