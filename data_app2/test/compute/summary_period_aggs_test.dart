import 'package:data_app2/user_events.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/util/summary_period_aggs.dart';
import 'package:test/test.dart';

void main() {
  final evtTypes = [
    EvtTypeRec(id: 1, name: "one"),
    EvtTypeRec(id: 2, name: "two"),
    EvtTypeRec(id: 3, name: "three"),
  ];
  test("empty", () {
    final aggs = computeAggs(Iterable.empty(), [], GroupFreq.week);
    expect(aggs, isEmpty);
  });
  test("simple (day)", () {
    final t = DateTime.now().startOfDay;
    // evts during 2 days
    final evts = [
      EvtRec.inCurrentTZ(
        typeId: 2,
        start: t.add(Duration(hours: 1)),
        end: t.add(Duration(hours: 2)),
      ),
      EvtRec.inCurrentTZ(
        typeId: 1,
        start: t.add(Duration(hours: 2)),
        end: t.add(Duration(hours: 3)),
      ),
      EvtRec.inCurrentTZ(
        typeId: 2,
        start: t.add(Duration(hours: 5)),
        end: t.add(Duration(hours: 5, minutes: 30)),
      ),
      EvtRec.inCurrentTZ(
        typeId: 3,
        start: t.add(Duration(hours: 25)),
        end: t.add(Duration(hours: 25, minutes: 30)),
      ),
    ];
    final aggs = computeAggs(evts, evtTypes, GroupFreq.day);
    expect(aggs, hasLength(2));

    // first day
    expect(aggs[0].dt, t);
    expect(aggs[0].agg, [
      Duration(hours: 1),
      Duration(minutes: 90),
      Duration.zero,
    ]);

    // second day
    expect(aggs[1].dt, t.add(Duration(days: 1)));
    expect(aggs[1].agg, [Duration.zero, Duration.zero, Duration(minutes: 30)]);
  });
  test("simple with gap (week)", () {
    // start from tuesday
    final t = DateTime.now().startOfweek.add(Duration(days: 1));
    // evts during 3 weeks, nothing in middle
    final evts = [
      EvtRec.inCurrentTZ(
        typeId: 2,
        start: t.add(Duration(hours: 1)),
        end: t.add(Duration(hours: 2)),
      ),
      EvtRec.inCurrentTZ(
        typeId: 1,
        start: t.add(Duration(hours: 50)),
        end: t.add(Duration(hours: 52)),
      ),
      EvtRec.inCurrentTZ(
        typeId: 2,
        start: t.add(Duration(days: 14, hours: 5)),
        end: t.add(Duration(days: 14, hours: 8)),
      ),
      EvtRec.inCurrentTZ(
        typeId: 3,
        start: t.add(Duration(days: 14, hours: 55)),
        end: t.add(Duration(days: 14, hours: 59)),
      ),
    ];
    final aggs = computeAggs(evts, evtTypes, GroupFreq.week);
    expect(aggs, hasLength(3));

    // first week
    expect(aggs[0].dt, t.startOfweek);
    expect(aggs[0].agg, [
      Duration(hours: 2),
      Duration(hours: 1),
      Duration.zero,
    ]);

    // second week
    expect(aggs[1].dt, t.startOfweek.add(Duration(days: 7)));
    expect(aggs[1].agg, [Duration.zero, Duration.zero, Duration.zero]);

    // third week
    expect(aggs[2].dt, t.startOfweek.add(Duration(days: 14)));
    expect(aggs[2].agg, [
      Duration.zero,
      Duration(hours: 3),
      Duration(hours: 4),
    ]);
  });
}
