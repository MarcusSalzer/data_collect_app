import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/export_service.dart';
import 'package:data_app2/importv2.dart';
import 'package:data_app2/raw_data_import_manager.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/stats.dart';
import 'package:test/test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/dummy_data.dart';
import '../test_util/paths.dart';

Future<Directory> export(AppState app) async {
  // export!
  final es = CompleteExportService(await getTmpDir(), DateTime.now());
  await es.exportAllDataRaw(app.db, app.prefs);
  return Directory(es.folderPath);
}

Future<ImportResult> import(AppState app, Directory folder) async {
  // clear app db
  await app.db.clear();

  // run import pipeline
  final im = RawDataImportManager(app.db, app.updatePrefs);
  await im.scan(folder);
  await im.preParse();

  return await im.import();
}

/// Big test that exports and imports all app data
/// Note that using the raw mode means that the database should be restored to the exact same state.
void main() {
  late final AppState app;
  setUpAll(() async {
    app = await getDummyApp();
  });
  tearDownAll(() async {
    await app.db.isar.close();
  });

  tearDown(() async {
    // Clear DB between tests
    await app.db.clear();
  });

  test("only prefs", () async {
    final myPrefs = AppPrefs(dayStartsH: 3, colorSpread: 0.12);
    await app.updatePrefs(myPrefs.copyWith());
    final folder = await export(app);
    // set other prefs
    await app.updatePrefs(AppPrefs(dayStartsH: 1, colorSpread: 0.1));

    final res = await import(app, folder);

    expect(res.counts.values.sum, 1, reason: "prefs should count as 1 item.");
    expect(app.prefs, myPrefs);
  });

  test("evts only", () async {
    await fillDbWithDummyData(app.db, nCats: 5, nTypes: 15, nEvts: 1000, nLocs: 0, nEnums: 0);

    final idsBefore = await getAllRepoIds(app.db);

    final folder = await export(app);
    final res = await import(app, folder);

    // check summary
    expect(res.counts[ImportFileRole.eventCats], 5);
    expect(res.counts[ImportFileRole.eventTypes], 15);
    expect(res.counts[ImportFileRole.events], 1000);

    // check database
    expect(await app.db.evtCats.count(), 5);
    expect(await app.db.evtTypes.count(), 15);
    expect(await app.db.evts.count(), 1000);

    final idsAfter = await getAllRepoIds(app.db);

    expect(idsAfter, idsBefore);
  });

  test("enums only", () async {
    await fillDbWithDummyData(app.db, nCats: 0, nTypes: 0, nEvts: 0, nLocs: 0, nEnums: 30);

    final idsBefore = await getAllRepoIds(app.db);

    final folder = await export(app);
    final res = await import(app, folder);

    // check summary
    expect(res.counts[ImportFileRole.enums], 30);

    // check database
    expect(await app.db.userEnums.count(), 30);

    final idsAfter = await getAllRepoIds(app.db);

    expect(idsAfter, idsBefore);
  });

  test("full dummy data", () async {
    await fillDbWithDummyData(app.db);

    final idsBefore = await getAllRepoIds(app.db);

    final folder = await export(app);
    final res = await import(app, folder);

    // check summary
    for (var MapEntry(key: role, value: count) in res.counts.entries) {
      expect(count, isPositive, reason: "should have some item from $role");
    }

    final idsAfter = await getAllRepoIds(app.db);

    expect(idsAfter, idsBefore);
  });
}
