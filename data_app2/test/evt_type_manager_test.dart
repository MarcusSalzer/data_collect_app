import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/util/colors.dart';
import 'package:data_app2/event_type_manager.dart';
import 'package:isar_community/isar.dart';
import 'package:test/test.dart';
import 'test_util/dummy_app.dart';

final exampleTypes = [EvtTypeRec(1, "a", ColorKey.amber), EvtTypeRec(2, "b", ColorKey.blue)];
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
      final newType = EvtTypeRec(13, "new");
      repo.add(newType);
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
      final newType = EvtTypeRec(14, "new");

      repo.add(newType);
      expect(notifyCount, 1);
    });
  });

  group('[with Persistence]', () {
    late Isar isar;
    late DBService db;
    late EvtTypeManagerPersist manager;
    setUp(() async {
      isar = await getTmpIsar();
      db = DBService(isar);
      manager = EvtTypeManagerPersist(db: db);
    });

    tearDown(() async {
      await isar.close();
      manager.dispose();
    });

    test('fill from models objects', () {
      manager.reloadFromModels(exampleTypes);

      expect(manager.all, exampleTypes);
    });

    // saveOrUpdate
    test('saveOrUpdate: adds to cache', () async {
      await manager.update(EvtTypeRec(11, "new"));
      expect(manager.resolveById(11), EvtTypeRec(11, "new"));
      expect(manager.resolveByName("new"), EvtTypeRec(11, "new"));
    });
    test('saveOrUpdate: persists', () async {
      await manager.update(EvtTypeRec(4, "new"));
      final fromDb = await db.eventTypes.getById(4);
      expect(fromDb, EvtTypeRec(4, "new"));
    });
    test('saveOrUpdate: updates', () async {
      await manager.update(EvtTypeRec(1, "new", ColorKey.blue));
      await manager.update(EvtTypeRec(1, "new", ColorKey.red));

      expect(manager.resolveById(1)?.color, ColorKey.red, reason: "repo should contain updated");
    });
  });
}
