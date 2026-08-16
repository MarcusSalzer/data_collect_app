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

    File(
      p.join(folder.path, "locations.csv"),
    ).writeAsStringSync(["name,lat,lng", "home,0.12,-1.5", "work,0.01,-11.5"].join("\n"));

    // events, referencing other data.
    File(
      p.join(folder.path, "events_all.csv"),
    ).writeAsStringSync(["type,location", "tA,", "tA,home", "tB,work", "tA,"].join("\n"));

    await vm.scanFolder();
    expect(vm.step, ImportStep.confirmFiles);
    // should have files to import
    expect(vm.candidates.canImport, true);

    await vm.prepareCsvRows();
    expect(vm.step, ImportStep.confirmImport);

    await vm.importToDb();
    expect(vm.error, isNull);
    expect(vm.step, ImportStep.done);
    expect(vm.result!.counts[ImportFileRole.events], 4);
    expect(vm.result!.counts[ImportFileRole.eventTypes], 3);
    expect(vm.result!.counts[ImportFileRole.eventCats], 2);
    expect(vm.result!.counts[ImportFileRole.locations], 2);

    expect((await app.db.evtTypes.all()).map((t) => t.name).toSet(), {"tA", "tB", "tC"});
    expect((await app.db.locations.all()).map((t) => t.name).toSet(), {"home", "work"});

    // Check type references
    final typs = (await app.db.evtTypes.all()).toList();
    expect(
      (await app.db.evts.all()).map((e) => typs.firstWhere((t) => t.id == e.typeId).name).toList(),
      ["tA", "tA", "tB", "tA"],
    );
    // Check location references
    final locs = (await app.db.locations.all()).toList();
    expect(
      (await app.db.evts.all())
          .map(
            (e) => locs.where((lo) => lo.id == e.locationId).firstOrNull?.name,
          )
          .toList(),
      [null, "home", "work", null],
    );
  });
}
