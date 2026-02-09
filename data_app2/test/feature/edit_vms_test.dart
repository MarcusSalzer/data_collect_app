import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/view_models/evt_cat_detail_vm.dart';
import 'package:data_app2/view_models/evt_type_detail_vm.dart';
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
      expect(vm.errorMsg, isNull);
    });

    test('delete', () async {
      await app.db.categories.create(EvtCatDraft("oops"));
      final rec = (await app.db.categories.all()).first;

      final vm = EvtCatDetailVm(rec, app);
      final didDel = await vm.delete();

      // expected state
      expect(didDel, true);
      expect(vm.errorMsg, isNull);
      expect(await app.db.categories.count(), 0);
    });

    test('does not delete if referenced', () async {
      await app.db.categories.create(EvtCatDraft("ok"));
      final rec = (await app.db.categories.all()).first;
      await app.db.eventTypes.create(EvtTypeDraft("hmm")..categoryId = rec.id);

      final vm = EvtCatDetailVm(rec, app);
      final didDel = await vm.delete();

      // expected state
      expect(didDel, false);
      expect(vm.isDirty, false);
      expect(vm.errorMsg, contains("will not delete"));
      expect(await app.db.categories.count(), 1);
    });
    test('update name & save', () async {
      await app.db.categories.create(EvtCatDraft("oops"));
      final rec = (await app.db.categories.all()).first;

      final vm = EvtCatDetailVm(rec, app);
      vm.updateName("corrected");
      expect(vm.isDirty, true);

      await vm.save();
      expect(vm.isDirty, false);
      expect(vm.errorMsg, isNull);
      expect((await app.db.categories.all()).first.name, "corrected");
    });
  });

  group('evtTypes', () {
    test('create', () async {
      final vm = EvtTypeDetailVm(null, app);

      expect(vm.stored, isNull);
      expect(vm.isDirty, true);
      // cannot delete if not stored
      expect(await vm.delete(), false);

      // give a name
      vm.updateName("hello");
      await vm.save();
      // saved
      expect((await app.db.eventTypes.all()).first.name, "hello");
      expect(vm.isDirty, false);
      expect(vm.errorMsg, isNull);
    });

    test('delete', () async {
      await app.db.eventTypes.create(EvtTypeDraft("oops"));
      final rec = (await app.db.eventTypes.all()).first;

      final vm = EvtTypeDetailVm(rec, app);
      final didDel = await vm.delete();

      // expected state
      expect(didDel, true);
      expect(await app.db.eventTypes.count(), 0);
      expect(vm.errorMsg, isNull);
    });

    test('does not delete if referenced', () async {
      await app.db.eventTypes.create(EvtTypeDraft("ok"));
      final rec = (await app.db.eventTypes.all()).first;
      await app.db.events.create(EvtDraft(rec.id, start: null, end: null));

      final vm = EvtTypeDetailVm(rec, app);
      final didDel = await vm.delete();

      // expected state
      expect(didDel, false);
      expect(vm.isDirty, false);
      expect(vm.errorMsg, contains("will not delete"));
      expect(await app.db.eventTypes.count(), 1);
    });
    test('update name & save', () async {
      await app.db.eventTypes.create(EvtTypeDraft("oops"));
      final rec = (await app.db.eventTypes.all()).first;

      final vm = EvtTypeDetailVm(rec, app);
      vm.updateName("corrected");
      expect(vm.isDirty, true);

      await vm.save();
      expect(vm.isDirty, false);
      expect(vm.errorMsg, isNull);
      expect((await app.db.eventTypes.all()).first.name, "corrected");
    });
    test('update category & save', () async {
      final catIds = await app.db.categories.createAll([EvtCatDraft("cat A"), EvtCatDraft("cat B")]);
      await app.db.eventTypes.create(EvtTypeDraft("hello"));
      final rec = (await app.db.eventTypes.all()).first;

      final vm = EvtTypeDetailVm(rec, app);
      await vm.load();
      expect(vm.categories?.length, 2);
      expect(vm.currentCategory, null);

      vm.updateCategory(catIds[1]);
      expect(vm.isDirty, true);
      expect(vm.currentCategory?.name, "cat B");

      await vm.save();
      expect(vm.isDirty, false);
      expect(vm.errorMsg, isNull);
      expect((await app.db.eventTypes.all()).first.categoryId, catIds[1]);
    });
  });
}
