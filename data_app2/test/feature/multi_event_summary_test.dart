import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/summary_with_period_aggs.dart';
import 'package:data_app2/util/process_state.dart';
import 'package:data_app2/view_models/multi_evt_summary_vm.dart';
import 'package:test/test.dart';
import '../test_util/dummy_app.dart';

void main() {
  late final AppState app;

  setUpAll(() async {
    app = await getDummyApp();
  });

  tearDown(() {
    //clear db and cache
    app.db.events.forceDeleteAll();
    app.db.eventTypes.forceDeleteAll();
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
