import 'package:data_app2/data/evt.dart';
import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_util/dummy_data.dart';

bool _acceptsDraft(UtcTimeRangeQuery q, EvtDraft d) => q.accepts(d.start!, d.end!);
void main() {
  final factory = SpecificEvtsFactory(dayStartOffset: Duration.zero, tzOffset: Duration(hours: 3));

  group('UTC', () {
    group('UTC inside', () {
      final q = UtcTimeRangeQuery(
        referenceUtc: factory.zeroUtcDt.subtract(Duration(days: 1)),
        unit: GroupFreq.day,
        overlapMode: OverlapMode.fullyInside,
      );
      setUpAll(() {
        expect(q.toString(), "(1969-12-31 00:00:00.000Z, 1970-01-01 00:00:00.000Z) fullyInside");
      });
      test('accepts with margin', () {
        expect(_acceptsDraft(q, factory.before(isLocal: false, margin: Duration(minutes: 1))), true);
      });
      test('rejects outside', () {
        expect(_acceptsDraft(q, factory.relative(isLocal: false, shift: Duration(days: 1, minutes: 1))), false);
      });
      test('rejects overlapping', () {
        expect(_acceptsDraft(q, factory.before(isLocal: false, overlap: Duration(minutes: 1))), false);
      });
    });
    group('UTC overlap', () {
      final q = UtcTimeRangeQuery(
        referenceUtc: factory.zeroUtcDt.subtract(Duration(days: 1)),
        unit: GroupFreq.day,
        overlapMode: OverlapMode.overlapping,
      );
      setUpAll(() {
        expect(q.toString(), "(1969-12-31 00:00:00.000Z, 1970-01-01 00:00:00.000Z) overlapping");
      });
      test('accepts with margin', () {
        expect(_acceptsDraft(q, factory.before(isLocal: false, margin: Duration(minutes: 1))), true);
      });
      test('rejects outside', () {
        expect(_acceptsDraft(q, factory.relative(isLocal: false, shift: Duration(days: 1, minutes: 1))), false);
      });
      test('accepts overlapping', () {
        expect(_acceptsDraft(q, factory.before(isLocal: false, overlap: Duration(minutes: 1))), true);
      });
    });
    group("toDb", () {
      final ref = DateTime.parse("1969-12-31 00:00:00.000Z");
      test('day', () {
        final q = UtcTimeRangeQuery(referenceUtc: ref, unit: GroupFreq.day, overlapMode: OverlapMode.fullyInside);
        final r = q.toDbRange();
        expect(r.startMs, ref.millisecondsSinceEpoch);
        expect(r.endMs, ref.add(Duration(days: 1)).millisecondsSinceEpoch);
        expect(r.overlap, q.overlapMode);
      });
      test('week', () {
        final q = UtcTimeRangeQuery(referenceUtc: ref, unit: GroupFreq.week, overlapMode: OverlapMode.fullyInside);
        final r = q.toDbRange();
        expect(DateTime.fromMillisecondsSinceEpoch(r.startMs, isUtc: true), ref.startOfweekUtc);
        expect(DateTime.fromMillisecondsSinceEpoch(r.endMs, isUtc: true), ref.startOfweekUtc.add(Duration(days: 7)));
      });
      test('month', () {
        final q = UtcTimeRangeQuery(referenceUtc: ref, unit: GroupFreq.month, overlapMode: OverlapMode.fullyInside);
        final r = q.toDbRange();
        expect(DateTime.fromMillisecondsSinceEpoch(r.startMs, isUtc: true), ref.startOfMonthUtc);
        expect(DateTime.fromMillisecondsSinceEpoch(r.endMs, isUtc: true), DateTime.parse("1970-01-01 00:00:00.000Z"));
      });
    });
  });
}
