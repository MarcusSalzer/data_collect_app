import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/util/colors.dart';
import 'package:data_app2/isar_models.dart';
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
      final newType = EvtTypeRec(1, "new");
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
    late EvtTypeManagerPersist repo;
    setUp(() async {
      isar = await getTmpIsar();
      repo = EvtTypeManagerPersist(db: DBService(isar));
    });

    tearDown(() async {
      await isar.close();
      repo.dispose();
    });

    test('fill from models objects', () {
      repo.reloadFromModels(exampleTypes);

      expect(repo.all, exampleTypes);
    });

    // saveOrUpdate
    test('saveOrUpdate: adds to cache', () async {
      await repo.update(EvtTypeRec(11, "new"));
      expect(repo.resolveById(11), EvtTypeRec(11, "new"));
      expect(repo.resolveByName("new"), EvtTypeRec(11, "new"));
    });
    test('saveOrUpdate: persists', () async {
      await repo.update(EvtTypeRec(4, "new"));
      final fromDb = await isar.eventTypes.get(4);
      expect(fromDb != null, true);
      expect(fromDb!, EvtTypeRec(4, "new"));
    });
    test('saveOrUpdate: updates', () async {
      await repo.update(EvtTypeRec(1, "new", ColorKey.blue));
      await repo.update(EvtTypeRec(1, "new", ColorKey.red));

      expect(repo.resolveById(1)?.color, ColorKey.red, reason: "repo should contain updated");
    });
  });
}
