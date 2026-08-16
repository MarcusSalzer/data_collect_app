import 'package:data_app2/app_state.dart';
import 'package:data_app2/view_models/evt_create_vm.dart';
import 'package:test/test.dart';
import '../test_util/dummy_app.dart';

void main() {
  late final AppState app;

  setUpAll(() async {
    app = await getDummyApp();
  });

  tearDown(() {
    //clear db and cache
    app.db.evts.forceDeleteAll();
    app.db.evtTypes.forceDeleteAll();
    app.evtTypeManager.clearCache();
  });

  group("create", () {
    test('new event type (auto lowercase off)', () async {
      final createVm = EvtCreateVm(app.db, app.evtTypeManager, false);

      await createVm.addEventByName("NEW!");

      final allEvts = (await app.db.evts.all()).toList();
      expect(allEvts.length, 1);
      expect(app.evtTypeManager.allTypes.length, 1);
      final et = app.evtTypeManager.typeFromId(allEvts[0].typeId);
      expect(et!.name, "NEW!");
    });
    test('new type (auto lowercase on)', () async {
      final createVm = EvtCreateVm(app.db, app.evtTypeManager, true);

      await createVm.addEventByName("NEW!");
      final allEvts = (await app.db.evts.all()).toList();
      expect(allEvts.length, 1);
      expect(app.evtTypeManager.allTypes.length, 1);
      final et = app.evtTypeManager.typeFromId(allEvts[0].typeId);
      expect(et!.name, "new!");
    });
    test('existing type', () async {
      final createVm = EvtCreateVm(app.db, app.evtTypeManager, true);

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
