import 'package:data_app2/app_state.dart';
import 'package:data_app2/view_models/event_create_vm.dart';
import 'package:test/test.dart';
import '../test_util/dummy_app.dart';

void main() {
  late final AppState app;
  late final EventCreateViewVM createVm;

  setUpAll(() async {
    app = await getDummyApp();
    createVm = EventCreateViewVM(app);
  });

  tearDown(() {
    //clear db and cache
    app.db.evts.forceDeleteAll();
    app.db.evtTypes.forceDeleteAll();
    app.evtTypeManager.clearCache();
  });

  group("create", () {
    test('new event type (auto lowercase off)', () async {
      await app.setAutoLowerCase(false);

      await createVm.addEventByName("NEW!");
      final allEvts = (await app.db.evts.all()).toList();
      expect(allEvts.length, 1);
      expect(app.evtTypeManager.allTypes.length, 1);
      final et = app.evtTypeManager.typeFromId(allEvts[0].typeId);
      expect(et!.name, "NEW!");
    });
    test('new type (auto lowercase on)', () async {
      await app.setAutoLowerCase(true);

      await createVm.addEventByName("NEW!");
      final allEvts = (await app.db.evts.all()).toList();
      expect(allEvts.length, 1);
      expect(app.evtTypeManager.allTypes.length, 1);
      final et = app.evtTypeManager.typeFromId(allEvts[0].typeId);
      expect(et!.name, "new!");
    });
    test('existing type', () async {
      await app.setAutoLowerCase(true);

      await createVm.addEventByName("NEW!");
      await createVm.addEventByName("new!");
      await createVm.addEventByName("nEw!");
      final allEvts = await app.db.evts.all();

      // 3 events, should count as the same type!
      expect(allEvts.length, 3);
      expect(app.evtTypeManager.allTypes.length, 1);
    });
  });
}
