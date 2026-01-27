import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/evt_csv_adapter.dart';
import 'package:data_app2/data/evt_draft.dart';
import 'package:data_app2/export_service.dart';
import 'package:data_app2/util/process_state.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

///
class EventExportViewModel extends ChangeNotifier {
  final AppState _app;
  final EvtCsvAdapter adapter = EvtCsvAdapter();

  ProcessState<({int nEvt, int nType, EvtDraft example})> state = Loading();

  EventExportViewModel(this._app);

  Future<void> load() async {
    state = Loading();
    notifyListeners();

    final ce = await _app.db.events.count();
    final ct = await _app.db.eventTypes.count();
    final ex = await _app.db.events.getOne();
    await Future.delayed(Duration(milliseconds: 400));

    if (ex != null) {
      state = Ready((
        nEvt: ce,
        nType: ct,
        example: EvtDraft.fromIsar(ex, _app.evtTypeManager.resolveById(ex.typeId)?.name ?? "unknown"),
      ));
    } else {
      state = Error("Has no events");
    }
    notifyListeners();
  }

  Future<void> doExport() async {
    if (state case Ready()) {
      state = Loading();
      notifyListeners();
      // Work on export

      final evts = await _app.db.events.all();
      final types = _app.evtTypeManager.all;
      // resolve all typenames before export
      final evtDrafts = await Future.wait<EvtDraft>(
        evts.map((e) async {
          final tp = _app.evtTypeManager.resolveById(e.typeId);
          // There shouldn't be events with unknown types.
          if (tp == null) {
            Logger.root.severe("[export] Unknown typeId: ${e.typeId}");
          }
          return EvtDraft.fromIsar(e, tp?.name ?? "unknown");
        }),
        eagerError: true,
      );

      /// export all data
      final counts = await CsvExportService(
        await _app.storeSubdir("export"),
        DateTime.now(),
      ).doExport(evtDrafts, types);

      state = Done(["events: ${counts.nEvt} lines", "types: ${counts.nType} lines"]);
    } else {
      state = Error("error, not ready");
    }
    notifyListeners();
  }
}
