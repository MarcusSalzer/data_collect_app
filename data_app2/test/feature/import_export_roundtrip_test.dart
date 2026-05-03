import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/daily_evt_summary_service.dart';
import 'package:data_app2/export_service.dart';
import 'package:data_app2/view_models/import_folder_vm.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/dummy_data.dart';
import '../test_util/paths.dart';

Future<void> exportImport(AppState app) async {
  // export!

  final es = CompleteExportService(await getTmpDir(), DateTime.now());
  await es.exportAllData(app.db, app.evtTypeManager, app.locationManager, app.prefs);

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
  test('DB fingerprint is preserved when exporting and importing', () async {
    // dummy app with dummy data
    final app = await getDummyApp();
    await fillDbWithDummyData(app.db);

    final summaryPre = await DailyEvtSummaryService(app.evtTypeManager, app.db).buildAll();
    await exportImport(app);
    final summaryPost = await DailyEvtSummaryService(app.evtTypeManager, app.db).buildAll();

    expect(summaryPost, summaryPre);
  });
}
