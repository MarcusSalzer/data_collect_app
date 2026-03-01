import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/month_vm.dart';
import 'package:test/test.dart';

import '../test_util/dummy_app.dart';

MonthVm getVm(AppState app, {SummaryMode sm = SummaryMode.type}) =>
    MonthVm(DateTime(2026, 1), Duration(hours: 2), app.db, app.evtTypeManager, 0.0, sm);

void main() {
  late final AppState app;
  setUpAll(() async {
    app = await getDummyApp();
  });

  setUp(() async {
    //clear db between tests
    await app.db.clear();
  });

  group('MonthVm', () {
    test('Init ok, no events', () async {
      // Jan 2026:
      // monday before: dec 29 2025 | last day: jan 31 (sat) | next sunday: feb 01
      final vm = getVm(app);

      expect(vm.days.first, DateTime(2025, 12, 29));
      expect(vm.days.last, DateTime(2026, 2, 1));
      expect(vm.eventList, isNull);
      await vm.load();
      expect(vm.eventList, isNotNull);
      // no events
      expect(vm.eventList!.isEmpty, true);
    });
    test('steps through a few months', () async {
      final vm = getVm(app);
      expect(vm.days.first, DateTime(2025, 12, 29));
      expect(vm.days.last, DateTime(2026, 2, 1));

      await vm.stepMonth(1);
      expect(vm.currentMonth, DateTime(2026, 2));
      expect(vm.days.first, DateTime(2026, 1, 26));
      expect(vm.days.last, DateTime(2026, 3, 1));

      await vm.stepMonth(1);
      expect(vm.currentMonth, DateTime(2026, 3));
      expect(vm.days.first, DateTime(2026, 2, 23));
      expect(vm.days.last, DateTime(2026, 4, 5));
    });
    test('can toggle summary mode', () {
      var nChange = 0;
      final vm = getVm(app, sm: SummaryMode.type);
      vm.addListener(() => nChange++);
      vm.setSummaryMode(SummaryMode.category);
      expect(nChange, 1);
      expect(vm.summaryMode, SummaryMode.category);

      // no-op
      vm.setSummaryMode(SummaryMode.category);
      expect(nChange, 1);

      // change
      vm.setSummaryMode(SummaryMode.type);
      expect(nChange, 2);
      expect(vm.summaryMode, SummaryMode.type);
    });
  });
}
