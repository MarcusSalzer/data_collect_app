import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/import_folder_vm.dart';
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
  });
}
