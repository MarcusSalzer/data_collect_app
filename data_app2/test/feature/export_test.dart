import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/export_service.dart';
import 'package:data_app2/prefs_io.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/paths.dart';

String correctName(DateTime now) {
  return "${DateFormat("yyyy-MM-ddTHH-mm-ss").format(now.toUtc())}Z";
}

Directory correctOutDir(Directory parentDir, DateTime now) => Directory(p.join(parentDir.path, correctName(now)));

/// Do a full import and export, using actual app services
void main() {
  late final AppState app;
  late final Directory parentDir;
  setUpAll(() async {
    parentDir = await getTmpDir();
    app = await getDummyApp();

    // Clear DB between tests
    await app.db.isar.writeTxn(() async => await app.db.isar.clear());
  });
  tearDown(() {
    if (parentDir.existsSync()) {
      parentDir.deleteSync(recursive: true);
    }
  });

  test("gets a timestamp-name", () async {
    final now = DateTime.now();
    final es = CompleteExportService(parentDir, now);
    expect(es.name, correctName(now));
  });

  test("throws exception if file exists", () async {
    final es = CompleteExportService(parentDir, DateTime.now());
    // export once
    await es.exportAllData(app.db, app.evtTypeManager, app.prefs);
    // should not be able to export again
    expect(() => es.exportAllData(app.db, app.evtTypeManager, app.prefs), throwsException);
  });

  test('writes empty', () async {
    final now = DateTime.now();
    final es = CompleteExportService(parentDir, now);
    await es.exportAllData(app.db, app.evtTypeManager, app.prefs);
    final folder = correctOutDir(parentDir, now);
    expect(folder.existsSync(), true);

    final childs = folder.listSync().map((f) => p.basename(f.path)).toSet();
    expect(childs, {"events_all.csv", "event_types.csv", "event_categories.csv", "prefs.json"});

    // check contents
    final evtLines = File(p.join(folder.path, "events_all.csv")).readAsLinesSync();
    final typeLines = File(p.join(folder.path, "event_types.csv")).readAsLinesSync();
    final catLines = File(p.join(folder.path, "event_categories.csv")).readAsLinesSync();

    // should be empty, except for csv headers
    expect(evtLines, [CsvSchemasConst.evt.writeCols.join(",")]);
    expect(typeLines, [CsvSchemasConst.evtType.writeCols.join(",")]);
    expect(catLines, [CsvSchemasConst.evtCat.writeCols.join(",")]);

    // read prefs
    expect((await PrefsIo.load(File(p.join(folder.path, "prefs.json"))))?.toJson(), app.prefs.toJson());
  });
}
