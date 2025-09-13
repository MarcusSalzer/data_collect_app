import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/csv/csv_format.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/process_state.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class EventExportViewModelComplicated extends ChangeNotifier {
  final AppState _app;
  SchemaLevel _schemaLevel = SchemaLevel.raw;

  SchemaLevel get schema => _schemaLevel;

  EventCsvAdapter eventAdapter() {
    return EventCsvAdapter(",", schema, _app.evtTypeRepo);
  }

  ProcessState<
      ({
        int nEvt,
        int nType,
        EvtRec example,
      })> state = Loading();

  EventExportViewModelComplicated(this._app);

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
        example: EvtRec.fromIsar(ex),
      ));
    }
    notifyListeners();
  }

  setSchema(SchemaLevel schema) {
    _schemaLevel = schema;
    notifyListeners();
  }

  Future<File> saveEventTypes(Directory folder) async {
    final adapter = EventTypeCsvAdapter(",", _schemaLevel);

    // get all types
    final types = await _app.db.getEventTypes();
    final lines = <String>[
      adapter.header,
      ...types.map(
        (e) => adapter.toRow(
          EvtTypeRec.fromIsar(e),
        ),
      )
    ];
    final file = File(
        p.join(folder.path, "event_types_${adapter.schemaLevel.name}.csv"));
    await file.create();

    await file.writeAsString(lines.join("\n"));
    return file;
  }

  Future<File> saveAllEvents(Directory folder) async {
    final adapter = EventCsvAdapter(",", _schemaLevel, _app.evtTypeRepo);
    final evts = await _app.db.getAllEvents();

    final lines = [
      adapter.header,
      ...evts.map(
        (e) => adapter.toRow(
          EvtRec.fromIsar(e),
        ),
      )
    ];
    final file =
        File(p.join(folder.path, "events_${adapter.schemaLevel.name}_all.csv"));
    await file.create();

    await file.writeAsString(lines.join("\n"));
    return file;
  }

  Future<void> doExport() async {
    final storePath = (await defaultStoreDir()).path;

    final folderName = Fmt.dtSecondSimple(DateTime.now().toUtc());
    final dir = Directory(p.join(storePath, 'export', folderName));

    if (state case Ready()) {
      if (await dir.exists()) {
        state = Error("Target already exists, wait and try again.");
        notifyListeners();
        return;
      }
      state = Loading();
      notifyListeners();
      // Work on export
      await dir.create(recursive: true);
      final savedTypes = await saveEventTypes(dir);
      final savedEvts = await saveAllEvents(dir);
      await Future.delayed(Duration(milliseconds: 100));
      state = Done([savedTypes.path, savedEvts.path]);
    } else {
      state = Error("error, not ready");
    }
    notifyListeners();
  }
}
