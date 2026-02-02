import 'package:data_app2/app_state.dart';
import 'package:data_app2/export_service.dart';
import 'package:data_app2/util/process_state.dart';
import 'package:flutter/material.dart';

/// For exporting all app data
class EventExportViewModel extends ChangeNotifier {
  final AppState _app;

  ProcessState<({int nEvt, int nType})> state = Loading();

  EventExportViewModel(this._app);

  Future<void> load() async {
    state = Loading();
    notifyListeners();

    final ce = await _app.db.events.count();
    final ct = await _app.db.eventTypes.count();
    await Future.delayed(Duration(milliseconds: 400));

    if (ce > 0) {
      state = Ready((nEvt: ce, nType: ct));
    } else {
      state = Error("Has no events");
    }
    notifyListeners();
  }

  Future<void> doExport() async {
    if (state case Ready()) {
      state = Loading();
      notifyListeners();

      /// export all data
      final counts = await CsvExportService(
        await _app.storeSubdir("export"),
        DateTime.now(),
      ).exportAllData(_app.db, _app.evtTypeManager);

      state = Done(counts.entries.map((e) => "${e.key}: ${e.value} lines").toList());
    } else {
      state = Error("error, not ready");
    }
    notifyListeners();
  }
}
