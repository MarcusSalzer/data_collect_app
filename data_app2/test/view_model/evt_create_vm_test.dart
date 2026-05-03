import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/view_models/evt_create_vm.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/dummy_data.dart';

void main() {
  late List<int> evtIds;
  late List<int> typeIds;
  final nEvt = 15;
  late final DBService db;
  late final EvtTypeManagerPersist typMan;

  setUpAll(() async {
    // init these only once
    db = await getDummyDb();
    typMan = EvtTypeManagerPersist(db);
  });

  setUp(() async {
    // refresh cache and clear db before each test
    typMan.clearCache();
    await db.clear();
    await fillDbWithDummyData(db, nEvts: nEvt);
    typMan.reloadFromModels(await db.evtTypes.all(), await db.evtCats.all());
    evtIds = (await db.evts.allIds()).toList();
    typeIds = (await db.evtTypes.allIds()).toList();
  });

  tearDownAll(() async {
    await db.isar.close();
  });

  group('Creating events', () {
    test('create by name (original case)', () async {
      final vm = EvtCreateVm(db, typMan, false);
      await vm.load();

      final t = DateTime.now(); // fixed time for stable testing
      await vm.addEventByName("NEWname", start: t);
      expect(vm.evts.length, evtIds.length + 1);

      final latest = vm.evts.last;

      // should store
      expect(await db.evts.getById(latest.id), latest);
      expect((await db.evtTypes.getById(latest.typeId))!.name, "NEWname");
    });
    test('create by name (lowercase, existing)', () async {
      var nNotify = 0;
      final vm = EvtCreateVm(db, typMan, true);
      await vm.load();
      vm.addListener(() => nNotify++);

      final typ = (await db.evtTypes.getById(typeIds.first))!;
      final t = DateTime.now(); // fixed time for stable testing
      await vm.addEventByName(typ.name.toUpperCase(), start: t);
      expect(nNotify, 1);
      expect(vm.evts.length, evtIds.length + 1);

      // should add to end of evts
      final latest = vm.evts.last;
      // should have a start time defined (now)
      expect(Fmt.time(latest.start?.asLocal), Fmt.time(t));

      // should store
      expect(await db.evts.getById(latest.id), latest);

      // should NOT make new type
      expect((await db.evtTypes.all()).length, typeIds.length);
    });
    test('create by name (lowercase, new)', () async {
      var nNotify = 0;
      final vm = EvtCreateVm(db, typMan, true);
      await vm.load();
      vm.addListener(() => nNotify++);

      final t = DateTime.now(); // fixed time for stable testing
      await vm.addEventByName("soMeNewName", start: t);
      expect(nNotify, 1);
      expect(vm.evts.length, evtIds.length + 1);

      // should add to end of evts
      final latest = vm.evts.last;
      // should have a start time defined (now)
      expect(Fmt.time(latest.start?.asLocal), Fmt.time(t));

      // should store
      expect(await db.evts.getById(latest.id), latest);

      // should make new type
      expect((await db.evtTypes.all()).length, typeIds.length + 1);
      expect((await db.evtTypes.getById(latest.typeId))!.name, "somenewname");
    });

    test('create by type', () async {
      var nNotify = 0;
      final vm = EvtCreateVm(db, typMan, true);
      await vm.load();
      vm.addListener(() => nNotify++);

      final typ = (await db.evtTypes.getById(typeIds.first))!;
      final t = DateTime.now(); // fixed time for stable testing
      await vm.addEventByTypeId(typ.id, start: t);
      expect(nNotify, 1);
      expect(vm.evts.length, evtIds.length + 1);

      // should add to end of evts
      final latest = vm.evts.last;
      // should have a start time defined (now)
      expect(Fmt.time(latest.start?.asLocal), Fmt.time(t));

      // should store
      expect(await db.evts.getById(latest.id), latest);

      // should NOT make new type
      expect((await db.evtTypes.all()).length, typeIds.length);
    });
  });
  group('VM functions', () {
    test('init and load', () async {
      var nNotify = 0;
      final vm = EvtCreateVm(db, typMan, false);
      vm.addListener(() => nNotify++);

      expect(vm.isReady, false);
      await vm.load();
      expect(nNotify, 1);
      expect(vm.isReady, true);
      expect(vm.evts.length, nEvt);
    });
    test('stop current event', () async {
      var nNotify = 0;
      final vm = EvtCreateVm(db, typMan, true);
      vm.addListener(() => nNotify++);
      // start evt
      await vm.addEventByName('test');

      expect(vm.current, isNotNull); // in progress
      await vm.stopCurrent();
      expect(nNotify, 2);
      expect(vm.current, isNull); // no longer in progress
      expect(vm.evts.last.end, isNotNull);
    });
    test('suggestions: returns something', () async {
      final vm = EvtCreateVm(db, typMan, true);
      await vm.load();
      final s = vm.suggestions;
      expect(s, isNotEmpty);
    });
  });
}
