import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:isar_community/isar.dart';
import 'package:test/test.dart';
import 'test_util/dummy_app.dart';
import 'test_util/dummy_data.dart';

final exampleTypes = SimpleDummyData.getDummyEvtTypes();
final exampleCats = SimpleDummyData.getDummyEvtCats();
void main() {
  group("[in memory]", () {
    test("resolve: get types", () {
      final manager = EvtTypeManager()..reloadFromModels(exampleTypes, exampleCats);
      expect(manager.typeFromId(1), exampleTypes[0]);
      expect(manager.typeFromName(exampleTypes[1].name), exampleTypes[1]);
    });
    test("resolve: missing types -> null", () {
      final manager = EvtTypeManager()..reloadFromModels(exampleTypes, exampleCats);
      expect(manager.typeFromId(393), null);
      expect(manager.typeFromName("thrash dont exist"), null);
    });

    test("add: can add and resolve", () {
      final manager = EvtTypeManager()..reloadFromModels(exampleTypes, exampleCats);
      final newType = EvtTypeRec(13, "new");
      manager.add(newType);
      // Id should be added
      expect(manager.typeFromId(13), newType);
      expect(manager.typeFromName("new"), newType);
      expect(manager.allTypes.length, exampleTypes.length + 1);
    });

    test("add: should notify", () {
      var notifyCount = 0;
      final manager = EvtTypeManager()..reloadFromModels(exampleTypes, exampleCats);
      manager.addListener(() {
        notifyCount++;
        expect(manager.allTypes.length, exampleTypes.length + notifyCount);
      });
      expect(notifyCount, 0);
      final newType = EvtTypeRec(14, "new");

      manager.add(newType);
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
      manager = EvtTypeManagerPersist(db);
    });

    tearDown(() async {
      await isar.close();
      manager.dispose();
    });

    test('fill from models objects', () {
      manager.reloadFromModels(exampleTypes, exampleCats);

      expect(manager.allTypes, exampleTypes);
    });
  });
}
