import 'package:data_app2/app_state.dart';
import 'package:data_app2/view_models/evt_cat_detail_vm.dart';
import 'package:test/test.dart';

import '../test_util/dummy_app.dart';

void main() {
  late final AppState app;
  setUpAll(() async {
    app = await getDummyApp();
  });

  setUp(() async {
    //clear db between tests
    await app.db.clear();
  });

  group('evtCats', () {
    test('create', () async {
      final vm = EvtCatDetailVm(null, app);

      expect(vm.stored, isNull);
      expect(vm.isDirty, true);
      // cannot delete if not stored
      expect(await vm.delete(), false);

      // give a name
      vm.updateName("hello");
      await vm.save();
      // saved
      expect((await app.db.categories.all()).first.name, "hello");
      expect(vm.isDirty, false);
    });
    test('delete', () {});
    test('update', () {});
  });
}
