import 'dart:io';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/infer_role.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/csv/evt_cat_csv.dart';
import 'package:data_app2/csv/evt_csv.dart';
import 'package:data_app2/csv/evt_type_csv.dart';
import 'package:data_app2/util/enums.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class ImportAnyVm extends ChangeNotifier {
  final String filePath;
  final AppState _app;
  ImportAnyVm(this.filePath, this._app) {
    load();
  }

  // === State ===
  ImportStep _step = ImportStep.scanningFolder; // progress through steps
  String? _errorMsg;
  CsvCodecRW? _codec; // infer this from file

  // === Public ===
  ImportStep get step => _step;
  String? get errorMsg => _errorMsg;
  CsvSchema? get schema => _codec?.schema;

  /// Load file
  Future<void> load() async {
    final cols = await getCsvHeaderCols(File(filePath));
    final role = roleFromFileName(p.basename(filePath));

    if (role == ImportFileRole.unknown) {
      _fail("Cannot import CSV with columns: '$cols'");
    } else {
      if (role == ImportFileRole.events) {
        _codec = EvtCsvCodecHuman(_app.evtTypeManager, _app.locationManager);
      } else if (role == ImportFileRole.eventTypes) {
        _codec = EvtTypeCsvCodecHuman.fromTypeManager(_app.evtTypeManager);
      } else if (role == ImportFileRole.eventCats) {
        _codec = EvtCatCsvCodecHuman();
      }
      _setStep(ImportStep.confirmImport);
    }
  }

  Future<void> doImport() async {
    _setStep(ImportStep.importing);
    final cod = _codec;
    if (cod == null) {
      _fail("no matching codec");
      return;
    }

    try {
      final rows = parseCsvRows(await File(filePath).readAsLines());
      if (cod is EvtCsvCodecHuman) {
        // Events
        await _app.db.evts.createAll(cod.decodeAll(rows));
      } else if (cod is EvtTypeCsvCodecHuman) {
        // Event types
        await _app.db.evtTypes.createAll(cod.decodeAll(rows));
      } else if (cod is EvtCatCsvCodecHuman) {
        // Event categoriues
        await _app.db.evtCats.createAll(cod.decodeAll(rows));
      }
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
}
