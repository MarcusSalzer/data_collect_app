import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/daily_evt_summary_service.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/export_service.dart';
import 'package:data_app2/view_models/import_folder_vm.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/dummy_data.dart';
import '../test_util/paths.dart';

Future<Directory> export(AppState app, {required bool human}) async {
  // export!
  final es = CompleteExportService(await getTmpDir(), DateTime.now());
  if (human) {
    await es.exportAllDataHuman(app.db, app.evtTypeManager, app.locationManager, app.prefs);
  } else {
    await es.exportAllDataRaw(app.db, app.prefs);
  }
  return Directory(es.folderPath);
}

Future<void> import(AppState app, Directory folder) async {
  // clear app db
  await app.db.clear();

  // run import pipeline
  final importVm = ImportFolderVm(folder, app);
  await importVm.scanFolder();
  await importVm.prepareCsvRows();
  await importVm.importToDb();
}

/// Map for comparing without ids
Future<Map<String, String>> evtToTypeMap(DBService db) async {
  final typs = await db.evtTypes.all();
  final evts = await db.evts.all();

  final typsById = {for (var t in typs) t.id: t};

  return {
    for (var e in evts)
      "${e.start?.toNaiveIso8601String(includeMs: false)}, ${e.end?.toNaiveIso8601String(includeMs: false)}":
          typsById[e.typeId]!.name,
  };
}

/// Map for comparing without ids
Future<Map<String, String>> evtToLocMap(DBService db) async {
  final locs = await db.locations.all();
  final evts = await db.evts.all();

  final locsById = {for (var lo in locs) lo.id: lo};
  // print("id->Location");
  // for (var e in locsById.entries) {
  //   print("  $e");
  // }

  return {
    for (var e in evts)
      "${e.start?.toNaiveIso8601String(includeMs: false)}, ${e.end?.toNaiveIso8601String(includeMs: false)}":
          locsById[e.locationId]?.name ?? "N/A",
  };
}

void main() {
  late final AppState app;
  setUpAll(() async {
    app = await getDummyApp();
  });
  tearDownAll(() async {
    await app.db.isar.close();
  });
  setUp(() async {
    // dummy app with dummy data
    await fillDbWithDummyData(app.db, nEvts: 15);
  });
  tearDown(() async {
    await app.db.clear();
  });

  group("Human (ignores id, only evts/typs/cats/locs)", () {
    test('object counts are preserved', () async {
      // Check item counts for these repos
      // Human mode cannot restore blobs! (also skips enums)
      final repos = <CrudRepo>[
        app.db.evts,
        app.db.evtTypes,
        app.db.evtCats,
        app.db.locations,
      ];
      final countsPre = await Future.wait(repos.map((r) => r.count()));
      final folder = await export(app, human: true);
      await import(app, folder);
      final countsPost = await Future.wait(repos.map((r) => r.count()));
      expect(countsPost, countsPre);
    });

    test('type names preserved', () async {
      final pre = (await app.db.evtTypes.all()).map((e) => e.name).toSet();

      final folder = await export(app, human: true);
      await import(app, folder);

      final post = (await app.db.evtTypes.all()).map((e) => e.name).toSet();

      expect(post, pre);
    });

    test('location names preserved', () async {
      final pre = (await app.db.locations.all()).map((e) => e.name).toSet();

      final folder = await export(app, human: true);
      await import(app, folder);

      final post = (await app.db.locations.all()).map((e) => e.name).toSet();

      expect(post, pre);
    });

    test('evt->type is preserved', () async {
      final mapPre = await evtToTypeMap(app.db);

      final folder = await export(app, human: true);
      await import(app, folder);
      final mapPost = await evtToTypeMap(app.db);

      expect(mapPost, mapPre);
    });
    test('evt->location is preserved', () async {
      final mapPre = await evtToLocMap(app.db);

      final folder = await export(app, human: true);
      await import(app, folder);

      final mapPost = await evtToLocMap(app.db);
      expect(mapPost, mapPre);
    });

    test('DB fingerprint is preserved when exporting and importing', () async {
      final summaryPre = await DailyEvtSummaryService(app.evtTypeManager, app.db).buildAll();
      final folder = await export(app, human: true);
      await import(app, folder);
      final summaryPost = await DailyEvtSummaryService(app.evtTypeManager, app.db).buildAll();

      expect(summaryPost, summaryPre);
    });
  });
}
