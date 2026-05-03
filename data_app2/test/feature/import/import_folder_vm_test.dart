import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/import_folder_vm.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import '../../test_util/dummy_app.dart';

void main() {
  late final AppState app;

  setUpAll(() async {
    app = await getDummyApp();
  });
  test('init', () async {
    final folder = await app.storeSubdir("empty_folder");
    final vm = ImportFolderVm(folder, app);

    expect(vm.step, ImportStep.scanningFolder);
    await vm.scanFolder();
    expect(vm.step, ImportStep.confirmFiles);
  });
  test('missing folder', () async {
    final vm = ImportFolderVm(Directory("does/not/exist"), app);
    await vm.scanFolder();
    expect(vm.step, ImportStep.error);
    expect(vm.error, contains("Could not find the directory"));
    expect(vm.candidates.canImport, false);
  });

  test('happy path', () async {
    await app.db.clear();
    final folder = await app.storeSubdir("empty_folder");
    final vm = ImportFolderVm(folder, app);

    // write valid data.
    // types
    File(
      p.join(folder.path, "event_types.csv"),
    ).writeAsStringSync(["name,category", "tA,c1", "tB,", "tC,c2"].join("\n"));
    // cats
    File(
      p.join(folder.path, "event_categories.csv"),
    ).writeAsStringSync(["name", "c1", "c2"].join("\n"));

    await vm.scanFolder();
    expect(vm.step, ImportStep.confirmFiles);
    // should have files to import
    expect(vm.candidates.canImport, true);

    await vm.prepareCsvRows();
    expect(vm.step, ImportStep.confirmImport);

    await vm.importToDb();
    expect(vm.error, isNull);
    expect(vm.step, ImportStep.done);
    expect(vm.result!.counts[ImportFileRole.eventTypes], 3);
    expect(vm.result!.counts[ImportFileRole.eventCats], 2);

    final types = (await app.db.evtTypes.all()).toList();
    expect(types.map((t) => t.name).toSet(), {"tA", "tB", "tC"});
  });
}
