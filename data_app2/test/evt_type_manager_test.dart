import 'package:data_app2/db_service.dart';
import 'package:data_app2/util/colors.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/event_type_manager.dart';
import 'package:data_app2/user_events.dart';
import 'package:isar_community/isar.dart';
import 'package:test/test.dart';

import 'test_util/dummy_app.dart';

final exampleTypes = [
  EvtTypeRec(id: 1, name: "a", color: ColorKey.amber),
  EvtTypeRec(id: 2, name: "b", color: ColorKey.blue),
];
void main() {
  group("[in memory]", () {
    test("resolve: get types", () {
      final repo = EvtTypeManager(types: exampleTypes);
      expect(repo.resolveById(1), exampleTypes[0]);
      expect(repo.resolveByName("b"), exampleTypes[1]);
    });
    test("resolve: missing types -> null", () {
      final repo = EvtTypeManager(types: exampleTypes);
      expect(repo.resolveById(3), null);
      expect(repo.resolveByName("bad"), null);
    });

    test("add: can add and resolve", () {
      final repo = EvtTypeManager(types: exampleTypes);
      final newType = EvtTypeRec(name: "new");
      repo.add(13, newType.copyWith());
      // Id should be added
      expect(repo.resolveById(13), newType.copyWith(id: 13));
      expect(repo.resolveByName("new"), newType.copyWith(id: 13));
      expect(repo.all.length, 3);
    });
    test("add: should notify", () {
      var notifyCount = 0;
      final repo = EvtTypeManager(types: exampleTypes);
      repo.addListener(() {
        notifyCount++;
        expect(repo.all.length, exampleTypes.length + notifyCount);
      });
      expect(notifyCount, 0);
      final newType = EvtTypeRec(name: "new");

      repo.add(14, newType);
      expect(notifyCount, 1);
    });
  });

  group('[with Persistence]', () {
    late Isar isar;
    late EvtTypeManagerPersist repo;
    setUp(() async {
      isar = await getTmpIsar();
      repo = EvtTypeManagerPersist(db: DBService(isar));
    });

    tearDown(() async {
      await isar.close();
      repo.dispose();
    });

    test('fill from Isar objects', () {
      repo.reloadFromIsar(exampleTypes.map((e) => e.toIsar()));

      expect(repo.all, exampleTypes);
    });

    // resolveOrCreate

    // saveOrUpdate
    test('saveOrUpdate: adds to cache', () async {
      final newId = await repo.saveOrUpdate(EvtTypeRec(name: "new"));
      expect(repo.resolveById(newId), EvtTypeRec(id: newId, name: "new"));
      expect(repo.resolveByName("new"), EvtTypeRec(id: newId, name: "new"));
    });
    test('saveOrUpdate: persists', () async {
      final newId = await repo.saveOrUpdate(EvtTypeRec(name: "new"));
      final fromDb = await isar.eventTypes.get(newId);
      expect(fromDb != null, true);
      expect(EvtTypeRec.fromIsar(fromDb!), EvtTypeRec(id: newId, name: "new"));
    });
    test('saveOrUpdate: updates', () async {
      final id1 = await repo.saveOrUpdate(
        EvtTypeRec(name: "new", color: ColorKey.blue),
      );
      final id2 = await repo.saveOrUpdate(
        EvtTypeRec(name: "new", color: ColorKey.red),
      );

      expect(id1, id2, reason: "Should keep same id on update");
      expect(
        repo.resolveById(id1)?.color,
        ColorKey.red,
        reason: "repo should contain updated",
      );
    });
  });
}
