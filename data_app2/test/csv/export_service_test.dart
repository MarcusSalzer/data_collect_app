import 'dart:io';

import 'package:data_app2/data/evt_draft.dart';
import 'package:data_app2/export_service.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

final evts = [
  EvtDraft(
    id: 1,
    typeName: "t1",
    start: LocalDateTime.fromDateTimeLocalTZ(DateTime(2020, 1, 1)),
    end: LocalDateTime.fromDateTimeLocalTZ(DateTime(2020, 1, 3)),
  ),
  EvtDraft(
    id: 2,
    typeName: "t1",
    start: LocalDateTime.fromDateTimeLocalTZ(DateTime(2020, 2, 1)),
    end: LocalDateTime.fromDateTimeLocalTZ(DateTime(2020, 2, 3)),
  ),
  EvtDraft(
    id: 2,
    typeName: "t2",
    start: LocalDateTime.fromDateTimeLocalTZ(DateTime(2020, 3, 1)),
    end: LocalDateTime.fromDateTimeLocalTZ(DateTime(2020, 3, 3)),
  ),
];
final types = [
  EvtTypeRec(name: "t1"),
  EvtTypeRec(name: "t2"),
  EvtTypeRec(name: "t3"),
  EvtTypeRec(name: "t4"),
];

void main() {
  late final Directory tempDir;
  WidgetsFlutterBinding.ensureInitialized();

  // get a temp folder for the tests
  setUpAll(() async {
    tempDir = Directory(p.join((await defaultTmpDir()).path, "test"));
  });
  // Clear temporary storage between tests
  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });
  test("gets a timestamp-name", () async {
    final dt = DateTime.now();
    final es = CsvExportService(tempDir, dt);
    expect(es.name, "${DateFormat("yyyy-MM-ddTHH-mm-ss").format(dt.toUtc())}Z");
  });
  test("writes files to folder", () async {
    final es = CsvExportService(tempDir, DateTime.now());
    final folder = Directory(es.folderPath);

    await es.doExport(evts, types);
    // Should make its folder
    expect(folder.existsSync(), true);
    expect(folder.path.endsWith(es.name), true);
    // should write two csv files
    final childs = folder.listSync().map((f) => f.path).toSet();
    expect(childs, {
      p.join(folder.path, "events_all.csv"),
      p.join(folder.path, "event_types.csv"),
    });

    // check contents
    final evtLines = File(
      p.join(folder.path, "events_all.csv"),
    ).readAsLinesSync();
    final typeLines = File(
      p.join(folder.path, "event_types.csv"),
    ).readAsLinesSync();

    // should have a header + one line per item
    expect(evtLines.length, evts.length + 1);
    expect(typeLines.length, types.length + 1);
  });

  test("throws exception if file exists", () async {
    final es = CsvExportService(tempDir, DateTime.now());
    // export once
    await es.doExport(evts, types);
    // should not be able to export again
    expect(() => es.doExport(evts, types), throwsException);
  });
}
