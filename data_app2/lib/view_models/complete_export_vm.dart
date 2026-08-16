import 'package:data_app2/app_state.dart';
import 'package:data_app2/export_service.dart';
import 'package:data_app2/util/process_state.dart';
import 'package:flutter/material.dart';

/// For exporting all app data
class CompleteExportVm extends ChangeNotifier {
  final AppState _app;

  String? savedFolder;

  ProcessState<({int nEvt, int nType})> state = Loading();

  CompleteExportVm(this._app);

  Future<void> load() async {
    state = Loading();
    notifyListeners();

    final ce = await _app.db.evts.count();
    final ct = await _app.db.evtTypes.count();

    state = Ready((nEvt: ce, nType: ct));
    notifyListeners();
  }

  Future<void> doExport() async {
    if (state case Ready()) {
      state = Loading();
      notifyListeners();

      final serv = CompleteExportService(await _app.storeSubdir("export"), DateTime.now());

      /// export all data
      // final counts = await serv.exportAllDataHuman(_app.db, _app.evtTypeManager, _app.locationManager, _app.prefs);
      final counts = await serv.exportAllDataRaw(_app.db, _app.prefs);

      state = Done(counts.entries.map((e) => "${e.key}: ${e.value} lines").toList());
      savedFolder = serv.folderPath;
    } else {
      state = Error("error, not ready");
    }
    notifyListeners();
  }
}
