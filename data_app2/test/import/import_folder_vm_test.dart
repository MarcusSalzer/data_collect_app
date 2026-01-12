import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/view_models/import_folder_vm.dart';
import 'package:test/test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/paths.dart';

void main() {
  late final AppState app;

  setUpAll(() async {
    final (_, userDir) = await tmpDirWithSubdir();

    app = AppState(DBService(await getTmpIsar()), AppPrefs(), userDir);
  });
  test('init', () async {
    final folder = await app.storeSubdir("empty_folder");
    final vm = ImportFolderVm(folder, app);
    expect(vm.step, ImportStep.scanningFolder);
  });
}
