import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/data/summary_with_period_aggs.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/util/process_state.dart';
import 'package:data_app2/view_models/multi_evt_summary_vm.dart';
import 'package:test/test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/paths.dart';

void main() {
  late final AppState app;

  setUpAll(() async {
    // Use a temporary directory for the test DB
    final (dir, userDir) = await tmpDirWithSubdir();

    final db = DBService(await getTmpIsar());
    app = AppState(db, AppPrefs(), userDir);
    // save prefs (defaults)
    await db.prefs.store(app.prefs.toIsar());
  });

  tearDown(() {
    //clear db and cache
    app.db.events.deleteAll();
    app.db.eventTypes.deleteAll();
    app.evtTypeManager.clearCache();
  });

  group("", () {
    test("empty", () async {
      final vm = MultiEvtSummaryVM(Iterable.empty(), app);

      // wait until init
      await vm.load();
      final state = vm.state;
      expect(state, isA<Ready<SummaryWithPeriodAggs>>());

      switch (state) {
        case Ready<SummaryWithPeriodAggs>(:final data):
          expect(data.aggs, isEmpty);
          expect(data.nTypes, 0);
          expect(data.typeRecs, isEmpty);
          break;
        default:
          fail('Expected Ready state, got $state');
      }
    });
  });
}
