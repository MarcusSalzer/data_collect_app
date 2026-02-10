import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/import_any_vm.dart';
import 'package:test/test.dart';

import '../../test_util/dummy_app.dart';
import '../../test_util/paths.dart';

Future<List<ImportStep>> collectImportSteps(ImportAnyVm vm, Future<void> Function() action) async {
  final steps = <ImportStep>[vm.step];

  void listener() {
    steps.add(vm.step);
  }

  vm.addListener(listener);
  await action();
  vm.removeListener(listener);

  return steps;
}

void main() {
  late final AppState app;
  setUpAll(() async {
    app = await getDummyApp();
  });
  setUp(() async {
    /// clear all data before test
    await app.db.clear();
  });
  test('happy path', () async {
    final file = await getTmpFile('event_types.csv');
    await file.writeAsString('name,category\nhello,\nworld,');

    // count notifications.
    // expects ~2 per step (start and end)
    var notifyCount = 0;

    final vm = ImportAnyVm(file.path, app);
    vm.addListener(() {
      notifyCount++;
    });

    await vm.load();
    expect(notifyCount, 2);
    expect(vm.step, ImportStep.confirmImport);
    expect(vm.errorMsg, isNull);

    await vm.doImport();
    expect(notifyCount, 4);

    expect(vm.step, ImportStep.done);
    // new data should be in DB.
    expect((await app.db.evtTypes.all()).map((e) => e.name).toSet(), {"hello", "world"});
  });

  test('unknown CSV columns results in error', () async {
    final file = await getTmpFile('unknown.csv');
    await file.writeAsString('foo,bar,baz\n1,2,3\n');

    final vm = ImportAnyVm(file.path, app);

    await vm.load();
    expect(vm.step, ImportStep.error);
    expect(vm.errorMsg, contains('Cannot import CSV with columns:'));
  });
}
