import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/today_summary_data.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/today_summary_vm.dart';
import 'package:test/test.dart';

import '../test_util/dummy_app.dart';

void main() {
  late final AppState app;
  setUpAll(() async {
    app = await getDummyApp();
  });

  tearDownAll(() async {
    await app.db.isar.close();
  });

  test("empty", () async {
    await app.db.clear();

    var nNotify = 0;
    final vm = TodaySummaryDisplayVm(Duration(hours: 1), app.db, app.evtTypeManager, 0.0, SummaryMode.type);
    vm.addListener(() => nNotify++);

    // null before load
    expect(vm.activeSummary, isNull);

    await vm.load();

    expect(vm.activeSummary, isNotNull);
    // no data
    expect(vm.eventList, isEmpty);
    expect(vm.activeSummary, isEmpty);
    expect(nNotify, 1);
    // even if types change, this should not notify, since no evts
    app.evtTypeManager.upsertType(EvtTypeRec(133, "newnew"));
    expect(nNotify, 1);
  });
  group('with events', () {
    setUp(() async {
      await app.db.clear();

      final evtTypes = [EvtTypeRec(1, "A"), EvtTypeRec(2, "B")];
      final evtCats = [EvtCatRec(1, "catA")];
      app.evtTypeManager.reloadFromModels(evtTypes, evtCats);

      final now = DateTime.now();
      final t = DateTime.utc(now.year, now.month, now.day);
      final tzo = now.timeZoneOffset;
      await app.db.evts.createAll([
        // before day start
        EvtDraft(
          1,
          start: LocalDateTime.fromUtcAndOffset(t.subtract(Duration(minutes: 4)), tzo),
          end: LocalDateTime.fromUtcAndOffset(t.add(Duration(minutes: 30)), tzo),
        ),
        //today
        EvtDraft(
          2,
          start: LocalDateTime.fromUtcAndOffset(t.add(Duration(hours: 2, minutes: 5)), tzo),
          end: LocalDateTime.fromUtcAndOffset(t.add(Duration(hours: 3)), tzo),
        ),
      ]);
    });

    test("includes events from today only", () async {
      var nNotify = 0;
      final vm = TodaySummaryDisplayVm(Duration(hours: 2), app.db, app.evtTypeManager, 0.0, SummaryMode.type);
      vm.addListener(() => nNotify++);

      await vm.load();
      expect(vm.eventList!.length, 1);
      expect(nNotify, 1);
      expect(vm.activeSummary, isA<DurationSummaryList<EvtTypeRec>>());
      expect(vm.activeSummary!.trackedTime, Duration(minutes: 55));
    });

    test("refreshes both summaries on load", () async {
      var nNotify = 0;
      final vm = TodaySummaryDisplayVm(Duration(hours: 2), app.db, app.evtTypeManager, 0.0, SummaryMode.category);
      vm.addListener(() => nNotify++);

      await vm.load();
      expect(vm.activeSummary, isA<DurationSummaryList<EvtCatRec>>());
      expect(vm.activeSummary!.trackedTime, Duration(minutes: 55));

      // new event
      final now = DateTime.now();
      final t = DateTime.utc(now.year, now.month, now.day);
      final tzo = now.timeZoneOffset;
      await app.db.evts.create(
        EvtDraft(
          2,
          start: LocalDateTime.fromUtcAndOffset(t.add(Duration(hours: 4, minutes: 30)), tzo),
          end: LocalDateTime.fromUtcAndOffset(t.add(Duration(hours: 5)), tzo),
        ),
      );

      await vm.load();
      expect(vm.activeSummary!.trackedTime, Duration(minutes: 85));
      vm.toggleSummaryLevel();
      expect(vm.activeSummary, isA<DurationSummaryList<EvtTypeRec>>());
      expect(vm.activeSummary!.trackedTime, Duration(minutes: 85));
    });
    test("refreshes on type change", () async {
      var nNotify = 0;
      final vm = TodaySummaryDisplayVm(Duration(hours: 2), app.db, app.evtTypeManager, 0.0, SummaryMode.type);
      vm.addListener(() => nNotify++);

      await vm.load();
      expect(vm.eventList!.length, 1);
      expect(nNotify, 1);
      // even if types change, this should notify
      app.evtTypeManager.upsertType(EvtTypeRec(133, "newnew"));
      expect(nNotify, 2);
    });
  });
}
