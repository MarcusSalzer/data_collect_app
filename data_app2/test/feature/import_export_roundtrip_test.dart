import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/daily_evt_summary_service.dart';
import 'package:data_app2/export_service.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/import_folder_vm.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/dummy_data.dart';
import '../test_util/paths.dart';

Future<void> exportImport(AppState app, ImportFileMode mode) async {
  // export!

  final es = CompleteExportService(await getTmpDir(), DateTime.now());
  if (mode == ImportFileMode.csvHuman) {
    await es.exportAllDataHuman(app.db, app.evtTypeManager, app.locationManager, app.prefs);
  } else {
    await es.exportAllDataRaw(app.db, app.prefs);
  }

  final folder = Directory(es.folderPath);

  // clear app db
  await app.db.clear();

  // run import pipeline
  final importVm = ImportFolderVm(folder, app);
  await importVm.scanFolder();
  await importVm.prepareCsvRows();
  await importVm.importToDb();
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
    await fillDbWithDummyData(app.db);
  });
  tearDown(() async {
    await app.db.clear();
  });

  group("Human", () {
    test('object counts are preserved', () async {
      // Check item counts for these repos
      // Human mode cannot restore blobs! (also skips enums)
      final repos = <CrudRepo>[
        app.db.evts,
        app.db.evtTypes,
        app.db.evtCats,
        app.db.locations,
        app.db.locations,
      ];
      final countsPre = await Future.wait(repos.map((r) => r.count()));
      await exportImport(app, ImportFileMode.csvHuman);
      final countsPost = await Future.wait(repos.map((r) => r.count()));

      expect(countsPost, countsPre);
    });
    test('DB fingerprint is preserved when exporting and importing', () async {
      final summaryPre = await DailyEvtSummaryService(app.evtTypeManager, app.db).buildAll();
      await exportImport(app, ImportFileMode.csvHuman);
      final summaryPost = await DailyEvtSummaryService(app.evtTypeManager, app.db).buildAll();

      expect(summaryPost, summaryPre);
    });
  });

  // group("Raw", () {
  //   test('object counts are preserved', () async {
  //     // Check item counts for these repos
  //     // Human mode cannot restore blobs! (also skips enums)
  //     final repos = <CrudRepo>[
  //       app.db.evts,
  //       app.db.evtTypes,
  //       app.db.evtCats,
  //       app.db.locations,
  //       app.db.locations,
  //     ];
  //     final countsPre = await Future.wait(repos.map((r) => r.count()));
  //     await exportImport(app, ImportFileMode.csvRaw);
  //     final countsPost = await Future.wait(repos.map((r) => r.count()));

  //     expect(countsPost, countsPre);
  //   });
  //   test('DB fingerprint is preserved when exporting and importing', () async {
  //     final summaryPre = await DailyEvtSummaryService(app.evtTypeManager, app.db).buildAll();
  //     await exportImport(app, ImportFileMode.csvRaw);
  //     final summaryPost = await DailyEvtSummaryService(app.evtTypeManager, app.db).buildAll();

  //     expect(summaryPost, summaryPre);
  //   });
  // });
}
