import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/csv_simple.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/process_state.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class EventExportViewModel extends ChangeNotifier {
  final AppState _app;
  final EvtSimpleCsvAdapter adapter = EvtSimpleCsvAdapter();

  ProcessState<
      ({
        int nEvt,
        int nType,
        EvtDraft example,
      })> state = Loading();

  EventExportViewModel(this._app);

  Future<void> load() async {
    state = Loading();
    notifyListeners();

    final ce = await _app.db.countEvents();
    final ct = await _app.db.countEventTypes();
    final ex = await _app.db.getOneEvent();
    await Future.delayed(Duration(milliseconds: 400));

    if (ex != null) {
      state = Ready((
        nEvt: ce,
        nType: ct,
        example: EvtDraft.fromIsar(
            ex, _app.evtTypeRepo.resolveById(ex.typeId)?.name ?? "unknown"),
      ));
    } else {
      state = Error("Has no events");
    }
    notifyListeners();
  }

  Future<File?> saveAllEvents(Directory folder) async {
    final evts = await _app.db.getAllEvents();
    List<String> lines;
    try {
      lines = [
        adapter.header,
        ...await Future.wait(
          evts.map(
            (e) async {
              var typeName = _app.evtTypeRepo.resolveById(e.typeId)?.name;

              return adapter.toRow(EvtDraft.fromIsar(e, typeName ?? "unknown"));
            },
          ),
        )
      ];
    } catch (e) {
      state = Error(e);
      return null;
    }

    final ts = Fmt.dtSecondSimple(DateTime.now().toUtc());
    final file = File(p.join(folder.path, "events_all_$ts.csv"));
    if (await file.exists()) {
      state = Error("Target already exists, wait and try again.");
      return null;
    }
    await file.create();

    await file.writeAsString(lines.join("\n"));
    return file;
  }

  Future<void> doExport() async {
    final storePath = (await defaultStoreDir()).path;

    final dir = Directory(p.join(storePath, 'export'));

    if (state case Ready()) {
      state = Loading();
      notifyListeners();
      // Work on export
      await dir.create(recursive: true);
      final savedEvtsFile = await saveAllEvents(dir);
      await Future.delayed(Duration(milliseconds: 100));
      if (savedEvtsFile != null) {
        state = Done([savedEvtsFile.path]);
      }
    } else {
      state = Error("error, not ready");
    }
    notifyListeners();
  }
}
