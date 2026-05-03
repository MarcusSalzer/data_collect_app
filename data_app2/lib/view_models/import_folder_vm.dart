import 'dart:io';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/importv2.dart';
import 'package:data_app2/util/enums.dart';
import 'package:flutter/foundation.dart';

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
  final Map<ImportCandidate, List<CsvRow>> rowsPerCand = {};

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

  Future<void> prepareCsvRows() async {
    _setStep(ImportStep.preparingModels);

    try {
      for (final entry in candidates.cands.entries) {
        final role = entry.key;
        final def = getRoleDef(_app, role);

        for (final cand in entry.value) {
          final rows = parseRows(await cand.file.readAsLines()).toList();

          def.validate?.call(rows);

          rowsPerCand[cand] = rows;
        }
      }

      _setStep(ImportStep.confirmImport);
    } catch (e) {
      _fail(e.toString());
    }
  }

  Future<void> importToDb() async {
    _setStep(ImportStep.importing);
    final res = ImportResult();
    const order = [
      ImportFileRole.eventCats,
      ImportFileRole.eventTypes,
      ImportFileRole.locations,
      ImportFileRole.events,
    ];
    try {
      for (final role in order) {
        final def = getRoleDef(_app, role);

        for (final cand in candidates.cands[role]!) {
          if (rowsPerCand[cand] case List<CsvRow> rows) {
            final c = await def.import(rows);
            res.add(role, c);
          }
        }

        //  side effects live HERE
        final sideEffect = def.afterAll;
        if (sideEffect != null) {
          await sideEffect();
        }
      }
      _result = res;
      _setStep(ImportStep.done);
    } catch (e) {
      _fail(e.toString());
    }
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
