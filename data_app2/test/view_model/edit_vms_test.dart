import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';
import 'package:data_app2/view_models/evt_cat_detail_vm.dart';
import 'package:data_app2/view_models/evt_detail_vm.dart';
import 'package:data_app2/view_models/evt_type_detail_vm.dart';
import 'package:test/test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/dummy_data.dart';

void main() {
  group('evtCats', () {
    late final DBService db;
    setUpAll(() async {
      db = await getDummyDb();
    });

    setUp(() async {
      //clear db between tests
      await db.clear();
    });
    tearDownAll(() async {
      // close DB when done
      await db.isar.close();
    });
    test('create', () async {
      final vm = EvtCatDetailVm(null, db);

      expect(vm.stored, isNull);
      expect(vm.isDirty, true);
      // cannot delete if not stored
      expect(await vm.delete(), false);

      // give a name
      vm.updateName("hello");
      await vm.save();
      // saved
      expect((await db.evtCats.all()).first.name, "hello");
      expect(vm.isDirty, false);
      expect(vm.errorMsg, isNull);
    });

    test('delete', () async {
      await db.evtCats.create(EvtCatDraft("oops"));
      final rec = (await db.evtCats.all()).first;

      final vm = EvtCatDetailVm(rec, db);
      final didDel = await vm.delete();

      // expected state
      expect(didDel, true);
      expect(vm.errorMsg, isNull);
      expect(await db.evtCats.count(), 0);
    });

    test('does not delete if referenced', () async {
      await db.evtCats.create(EvtCatDraft("ok"));
      final rec = (await db.evtCats.all()).first;
      await db.evtTypes.create(EvtTypeDraft("hmm")..categoryId = rec.id);

      final vm = EvtCatDetailVm(rec, db);
      final didDel = await vm.delete();

      // expected state
      expect(didDel, false);
      expect(vm.isDirty, false);
      expect(vm.errorMsg, contains("will not delete"));
      expect(await db.evtCats.count(), 1);
    });
    test('update name & save', () async {
      await db.evtCats.create(EvtCatDraft("oops"));
      final rec = (await db.evtCats.all()).first;

      final vm = EvtCatDetailVm(rec, db);
      vm.updateName("corrected");
      expect(vm.isDirty, true);

      await vm.save();
      expect(vm.isDirty, false);
      expect(vm.errorMsg, isNull);
      expect((await db.evtCats.all()).first.name, "corrected");
    });
  });

  group('evtTypes', () {
    late final DBService db;
    late final EvtTypeManagerPersist typManager;
    setUpAll(() async {
      db = await getDummyDb();
      typManager = EvtTypeManagerPersist(db);
    });

    setUp(() async {
      //clear db between tests
      await db.clear();
    });
    tearDownAll(() async {
      // close DB when done
      await db.isar.close();
    });
    test('create', () async {
      final vm = EvtTypeDetailVm(null, db, typManager);

      expect(vm.stored, isNull);
      expect(vm.isDirty, true);
      // cannot delete if not stored
      expect(await vm.delete(), false);

      // give a name
      vm.updateName("hello");
      await vm.save();
      // saved
      expect((await db.evtTypes.all()).first.name, "hello");
      expect(vm.isDirty, false);
      expect(vm.errorMsg, isNull);
    });

    test('delete', () async {
      await db.evtTypes.create(EvtTypeDraft("oops"));
      final rec = (await db.evtTypes.all()).first;

      final vm = EvtTypeDetailVm(rec, db, typManager);
      final didDel = await vm.delete();

      // expected state
      expect(didDel, true);
      expect(await db.evtTypes.count(), 0);
      expect(vm.errorMsg, isNull);
    });

    test('does not delete if referenced', () async {
      await db.evtTypes.create(EvtTypeDraft("ok"));
      final rec = (await db.evtTypes.all()).first;
      await db.evts.create(EvtDraft(rec.id, start: null, end: null));

      final vm = EvtTypeDetailVm(rec, db, typManager);
      final didDel = await vm.delete();

      // expected state
      expect(didDel, false);
      expect(vm.isDirty, false);
      expect(vm.errorMsg, contains("will not delete"));
      expect(await db.evtTypes.count(), 1);
    });
    test('update name & save', () async {
      await db.evtTypes.create(EvtTypeDraft("oops"));
      final rec = (await db.evtTypes.all()).first;

      final vm = EvtTypeDetailVm(rec, db, typManager);
      vm.updateName("corrected");
      expect(vm.isDirty, true);

      await vm.save();
      expect(vm.isDirty, false);
      expect(vm.errorMsg, isNull);
      expect((await db.evtTypes.all()).first.name, "corrected");
    });
    test('update category & save', () async {
      final catIds = await db.evtCats.createAll([EvtCatDraft("cat A"), EvtCatDraft("cat B")]);
      await db.evtTypes.create(EvtTypeDraft("hello"));
      final rec = (await db.evtTypes.all()).first;

      final vm = EvtTypeDetailVm(rec, db, typManager);
      await vm.load();
      expect(vm.categories?.length, 2);
      expect(vm.currentCategory?.id, EvtCatRepo.defaultId);

      vm.updateCategory(catIds[1]);
      expect(vm.isDirty, true);
      expect(vm.currentCategory?.name, "cat B");

      await vm.save();
      expect(vm.isDirty, false);
      expect(vm.errorMsg, isNull);
      expect((await db.evtTypes.all()).first.categoryId, catIds[1]);
    });
  });

  group("events", () {
    late final DBService db;
    late final EvtTypeManager typManager;
    setUpAll(() async {
      db = await getDummyDb();
      await fillDbWithDummyData(db);
      typManager = EvtTypeManagerPersist(db);
      final (typs, cats) = await db.allTypesAndCats();
      typManager.reloadFromModels(typs, cats);
    });

    test("update type", () async {
      final typs = typManager.allTypes;
      final og = EvtRec.inCurrentTZ(133, typs[0].id, start: null, end: null);
      final vm = EvtDetailVm(og, db.evts, typManager);
      // start not dirty
      expect(vm.isDirty, false);

      vm.changeType(typs[1].id);
      expect(vm.isDirty, true);
      expect(vm.stored?.typeId, typs[0].id); // not saved
      expect(vm.draft.typeId, typs[1].id);

      await vm.save();
      expect(vm.isDirty, false);
      expect(vm.stored?.typeId, typs[1].id); // saved
      expect(vm.draft.typeId, typs[1].id);

      // check db
      final loaded = await db.evts.getById(og.id);
      expect(loaded?.typeId, typs[1].id);
    });
    test("update location", () {
      //
    });
    test("update start", () {
      //
    });
    test("update end", () {
      //
    });
    test("delete", () {
      //
    });
  });
}
