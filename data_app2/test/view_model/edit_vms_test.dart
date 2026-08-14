import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/location_manager.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';
import 'package:data_app2/view_models/blob_schema_edit_vm.dart';
import 'package:data_app2/view_models/evt_cat_detail_vm.dart';
import 'package:data_app2/view_models/evt_detail_vm.dart';
import 'package:data_app2/view_models/evt_type_detail_vm.dart';
import 'package:data_app2/view_models/location_edit_vm.dart';
import 'package:data_app2/view_models/user_enum_edit_vm.dart';
import 'package:test/test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/dummy_data.dart';

void main() {
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
  group('evtCats', () {
    test('create', () async {
      final vm = EvtCatDetailVm(null, db);

      expect(vm.stored, isNull);
      expect(vm.hasStored, false);
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

      var nNotify = 0;
      final vm = EvtCatDetailVm(rec, db);
      vm.addListener(() {
        nNotify++;
      });
      final didDel = await vm.delete();

      // expected state
      expect(didDel, false);
      expect(vm.isDirty, false);
      expect(nNotify, 1);
      expect(vm.errorMsg, contains("will not delete"));
      expect(await db.evtCats.count(), 1);

      // can dismiss error
      vm.dismissError();
      expect(vm.errorMsg, isNull);
      expect(nNotify, 2);
    });
    test('update name & save', () async {
      await db.evtCats.create(EvtCatDraft("oops"));
      final rec = (await db.evtCats.all()).first;

      final vm = EvtCatDetailVm(rec, db);
      expect(vm.hasStored, true);
      vm.updateName("corrected");
      expect(vm.isDirty, true);

      await vm.save();
      expect(vm.isDirty, false);
      expect(vm.errorMsg, isNull);
      expect((await db.evtCats.all()).first.name, "corrected");
    });
  });

  group('evtTypes', () {
    late final EvtTypeManagerPersist typManager;
    setUpAll(() async {
      typManager = EvtTypeManagerPersist(db);
    });

    setUp(() async {
      //clear db between tests
      await db.clear();
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
    late final EvtTypeManager typManager;
    setUpAll(() async {
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
  group("locations", () {
    // location manager/cache needed
    final locMan = LocationManager();

    test("valid, not dirty when opens existing", () async {
      final item = LocationRec(123, name: "old", lat: 9.99, lng: 12.22);
      final vm = LocationEditVm(existing: item, repo: db.locations, manager: locMan);

      expect(vm.stored, item);
      expect(vm.isValid, true, reason: "existing should be valid");
      expect(vm.isDirty, false, reason: "existing should not be dirty");
    });

    test("create", () async {
      final vm = LocationEditVm(existing: null, repo: db.locations, manager: locMan);

      expect(vm.stored, isNull);
      expect(vm.isDirty, false, reason: "should not be dirty when not edited.");
      expect(vm.isValid, false, reason: "should not be valid when empty");

      // give a name
      vm.setName("hello");
      expect(vm.isDirty, true, reason: "should be dirty after edit.");

      await vm.save();
      // saved
      expect((await db.locations.all()).first.name, "hello");
      expect(vm.isDirty, false, reason: "should not be dirty after save.");
      expect(vm.errorMsg, isNull);
    });
  });

  group("enums", () {
    test("not dirty, not valid when not edited", () async {
      final vm = UserEnumEditVm(null, db);
      await vm.load();

      expect(vm.isDirty, false, reason: "should not be dirty when not edited.");
      expect(vm.isValid, false);
    });

    test("valid, not dirty when opens existing", () async {
      final item = UserEnumRec(13, name: "myenum");
      final vm = UserEnumEditVm(item, db);

      await vm.load();

      expect(vm.stored, item);
      expect(vm.isValid, true, reason: "existing should be valid");
      expect(vm.isDirty, false, reason: "existing should not be dirty");
    });

    test("loads values", () async {
      final item = UserEnumRec(13, name: "myenum");

      final values = [
        for (var i in await db.userEnumValues.createAll(
          [
            UserEnumValueDraft(item.id, "vA"),
            UserEnumValueDraft(item.id, "vB"),
          ],
        ))
          (await db.userEnumValues.getById(i))!,
      ];

      // make some other values
      await db.userEnumValues.createAll([
        UserEnumValueDraft(item.id + 1, "vC"),
        UserEnumValueDraft(item.id + 1, "vD"),
        UserEnumValueDraft(item.id + 2, "vE"),
      ]);

      final vm = UserEnumEditVm(item, db);

      await vm.load();
      expect(vm.valueNameDrafts, values.map((v) => v.name).toSet());
    });

    test("add & remove values", () async {
      final item = UserEnumRec(13, name: "myenum");
      final vm = UserEnumEditVm(item, db);
      await vm.load();

      vm.addValue("newA");
      vm.addValue("newB");

      expect(vm.valueNameDrafts, {"newA", "newB"}, reason: "Should update working-set");

      await vm.save();
      // load and check matches
      expect((await db.userEnumValues.all()).map((v) => (v.enumId, v.name)), [
        (item.id, "newA"),
        (item.id, "newB"),
      ]);

      vm.removeValue("newA");
      // add and remove without saving
      vm.addValue("typo");
      vm.removeValue("typo");

      expect(vm.valueNameDrafts, {"newB"}, reason: "Should update working-set");

      await vm.save();
      // load and check matches
      expect((await db.userEnumValues.all()).map((v) => (v.enumId, v.name)), [
        (item.id, "newB"),
      ]);
      expect(vm.errorMsg, isNull);
    });

    test("error when removing non-existent.", () async {
      final item = UserEnumRec(13, name: "myenum");
      final vm = UserEnumEditVm(item, db);
      await vm.load();
      vm.addValue("newA");
      vm.removeValue("NonExist");

      expect(vm.errorMsg, contains("could not remove"));
      expect(vm.valueNameDrafts, {"newA"});
    });
  });

  group("blob schemas", () {
    test("not dirty, not valid when not edited", () {
      final vm = BlobSchemaEditVm(null, db.blobSchemas, db.userEnums);
      expect(vm.isDirty, false, reason: "should not be dirty when not edited.");
      expect(vm.isValid, false);
    });

    test("valid, not dirty when opens existing", () async {
      final item = BlobSchemaRec(
        13,
        name: "myschema",
        fields: {"myField": BlobFieldSpec(DDecimal())},
        evtLink: EvtLinkSpec.allTypes(),
      );
      final vm = BlobSchemaEditVm(item, db.blobSchemas, db.userEnums);

      expect(vm.stored, item);
      expect(vm.isValid, true, reason: "existing should be valid");
      expect(vm.isDirty, false, reason: "existing should not be dirty");
    });

    test("without enums", () async {
      final vm = BlobSchemaEditVm(null, db.blobSchemas, db.userEnums);
      await vm.load();

      expect(vm.enumGroupNames, isNotNull);
      expect(vm.enumGroupNames, isEmpty);
    });
    test("loads enums", () async {
      await db.userEnums.createAll([UserEnumDraft("e1"), UserEnumDraft("e2")]);
      final vm = BlobSchemaEditVm(null, db.blobSchemas, db.userEnums);
      await vm.load();

      expect(vm.enumGroupNames, ["e1", "e2"]);
    });
    test("create", () async {
      final vm = BlobSchemaEditVm(null, db.blobSchemas, db.userEnums);
      vm.setName("new");
      expect(vm.isDirty, false, reason: "only name, not dirty");
      expect(vm.isValid, false, reason: "no fields -> not valid");
      vm.addField("f1", BlobFieldSpec(DDecimal()));

      expect(vm.isDirty, true);
      expect(vm.isValid, true);

      // save and load
      await vm.save();
      expect(vm.isDirty, false, reason: "should not be dirty after save.");
      expect(vm.errorMsg, isNull);

      final loaded = (await db.blobSchemas.all()).first;
      expect(loaded.name, "new");
      expect(loaded.fields["f1"], BlobFieldSpec(DDecimal()));
    });
    test("add & remove fields", () async {
      final vm = BlobSchemaEditVm(null, db.blobSchemas, db.userEnums);
      vm.setName("new");

      vm.addField("f1", BlobFieldSpec(DDecimal()));

      //add and remove without saving
      vm.addField("f2", BlobFieldSpec(DBool()));
      vm.removeField("f2");

      // save and load
      await vm.save();
      final loaded = (await db.blobSchemas.all()).first;
      expect(loaded.name, "new");
      expect(loaded.fields["f1"], BlobFieldSpec(DDecimal()));

      // remove a saved field
      vm.removeField("f1");
      await vm.save();
      expect((await db.blobSchemas.all()).first.fields, isEmpty, reason: "should delete fields");
    });

    test("delete schema", () async {
      final id = await db.blobSchemas.create(
        TestDummyData.makeBlobSchemaAllTypes(UserEnumRec(1, name: "enum")).toDraft(),
      );
      final vm = BlobSchemaEditVm((await db.blobSchemas.getById(id))!, db.blobSchemas, db.userEnums);
      final d = await vm.delete();
      expect(d, true);
      expect(await db.blobSchemas.count(), 0);
      expect(vm.stored, isNull);
    });
  });

  test("change evtLink", () async {
    final item = BlobSchemaRec(
      13,
      name: "myschema",
      fields: {"myField": BlobFieldSpec(DDecimal())},
      evtLink: EvtLinkSpec.allTypes(),
    );
    final vm = BlobSchemaEditVm(item, db.blobSchemas, db.userEnums);
    await vm.save();

    expect((await db.blobSchemas.all()).first.evtLink, EvtLinkSpec.allTypes());

    // change & save
    vm.setEvtLink(null);
    await vm.save();

    expect((await db.blobSchemas.all()).first.evtLink, null);
  });
}
