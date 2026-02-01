import 'dart:io';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/infer_from_header.dart';
import 'package:data_app2/csv_2/csv_schema.dart';
import 'package:data_app2/csv_2/evt_cat_csv.dart';
import 'package:data_app2/csv_2/evt_csv.dart';
import 'package:data_app2/csv_2/evt_type_csv.dart';
import 'package:data_app2/util/enums.dart';
import 'package:flutter/material.dart';

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

  /// Load file
  Future<void> load() async {
    final cols = await getCsvHeaderCols(File(filePath));
    final role = roleFromCols(cols);

    if (role == ImportFileRole.unknown) {
      _fail("Cannot import CSV with columns: '$cols'");
    } else {
      if (role == ImportFileRole.events) {
        _codec = EvtCsvCodec(typMan: _app.evtTypeManager);
      } else if (role == ImportFileRole.eventTypes) {
        _codec = EvtTypeCsvCodec();
      } else if (role == ImportFileRole.eventCats) {
        _codec = EvtCatCsvCodec();
      }
      _setStep(ImportStep.confirmImport);
    }
  }

  Future<void> doImport() async {
    _setStep(ImportStep.importing);

    final lines = await File(filePath).readAsLines();

    final cod = _codec;
    if (cod == null) {
      _fail("no matching codec");
    } else {
      final rows = cod.parseRows(lines);
      if (cod is EvtCsvCodec) {
        // Events
        await _app.db.events.createAll(cod.decode(rows));
      } else if (cod is EvtTypeCsvCodec) {
        // Event types
        await _app.db.eventTypes.createAll(cod.decode(rows));
      } else if (cod is EvtCatCsvCodec) {
        // Event categoriues
        await _app.db.categories.createAll(cod.decode(rows));
      }
    }
    _setStep(ImportStep.done);
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
