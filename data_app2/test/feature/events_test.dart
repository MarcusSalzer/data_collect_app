import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/view_models/event_create_vm.dart';
import 'package:test/test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/paths.dart';

void main() {
  late final AppState app;
  late final EventCreateViewVM createVm;

  setUpAll(() async {
    final (dir, userDir) = await tmpDirWithSubdir();

    final db = DBService(await getTmpIsar());
    app = AppState(db, AppPrefs(), userDir);
    // save prefs (defaults)
    await db.prefs.store(app.prefs.toIsar());

    createVm = EventCreateViewVM(app);
  });

  tearDown(() {
    //clear db and cache
    app.db.events.deleteAll();
    app.db.eventTypes.deleteAll();
    app.evtTypeManager.clearCache();
  });

  group("create", () {
    test('new event type (auto lowercase off)', () async {
      await app.setAutoLowerCase(false);

      await createVm.addEventByName("NEW!");
      final allEvts = await app.db.events.all();
      expect(allEvts.length, 1);
      expect(app.evtTypeManager.all.length, 1);
      final et = app.evtTypeManager.resolveById(allEvts[0].typeId);
      expect(et!.name, "NEW!");
    });
    test('new type (auto lowercase on)', () async {
      await app.setAutoLowerCase(true);

      await createVm.addEventByName("NEW!");
      final allEvts = await app.db.events.all();
      expect(allEvts.length, 1);
      expect(app.evtTypeManager.all.length, 1);
      final et = app.evtTypeManager.resolveById(allEvts[0].typeId);
      expect(et!.name, "new!");
    });
    test('existing type', () async {
      await app.setAutoLowerCase(true);

      await createVm.addEventByName("NEW!");
      await createVm.addEventByName("new!");
      await createVm.addEventByName("nEw!");
      final allEvts = await app.db.events.all();

      // 3 events, should count as the same type!
      expect(allEvts.length, 3);
      expect(app.evtTypeManager.all.length, 1);
    });
  });
}
