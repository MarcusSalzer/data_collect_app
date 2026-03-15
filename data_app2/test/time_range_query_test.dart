import 'package:data_app2/data/evt.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_util/dummy_data.dart';

bool _acceptsDraft(TimeRangeQuery q, EvtDraft d) => q.accepts(d.start!, d.end!);

void main() {
  group('UTC', () {
    final factory = SpecificEvtsFactory(dayStartOffset: Duration.zero, tzOffset: Duration(hours: 3));
    group('UTC inside', () {
      final q = UtcTimeRangeQuery(
        ref: factory.zeroUtcDt.subtract(Duration(days: 1)),
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
        ref: factory.zeroUtcDt.subtract(Duration(days: 1)),
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
        final q = UtcTimeRangeQuery(ref: ref, unit: GroupFreq.day, overlapMode: OverlapMode.fullyInside);
        final r = q.toDbRange();
        expect(r.startMs, ref.millisecondsSinceEpoch);
        expect(r.endMs, ref.add(Duration(days: 1)).millisecondsSinceEpoch);
        expect(r.overlap, q.overlapMode);
      });
      test('week', () {
        final q = UtcTimeRangeQuery(ref: ref, unit: GroupFreq.week, overlapMode: OverlapMode.fullyInside);
        final r = q.toDbRange();
        expect(DateTime.fromMillisecondsSinceEpoch(r.startMs, isUtc: true), ref.startOfweekUtc);
        expect(DateTime.fromMillisecondsSinceEpoch(r.endMs, isUtc: true), ref.startOfweekUtc.add(Duration(days: 7)));
      });
      test('month', () {
        final q = UtcTimeRangeQuery(ref: ref, unit: GroupFreq.month, overlapMode: OverlapMode.fullyInside);
        final r = q.toDbRange();
        expect(DateTime.fromMillisecondsSinceEpoch(r.startMs, isUtc: true), ref.startOfMonthUtc);
        expect(DateTime.fromMillisecondsSinceEpoch(r.endMs, isUtc: true), DateTime.parse("1970-01-01 00:00:00.000Z"));
      });
    });
  });
  group('Local', () {
    // minutes -> avoid confusion with timezone
    final dayOffset = Duration(minutes: 5);
    final today = DateTime(2026, 3, 12);

    group('inside', () {
      final q = LocalTimeRangeQuery(
        dayOffset: dayOffset,
        ref: today,
        unit: GroupFreq.day,
        overlapMode: OverlapMode.fullyInside,
      );
      setUpAll(() {
        expect(q.toString(), "(2026-03-12 00:05:00.000, 2026-03-13 00:05:00.000) fullyInside");
      });

      test('accepts with margin', () {
        final d = EvtDraft.inCurrentTZ(
          1,
          start: today.add(dayOffset + Duration(minutes: 1)),
          end: today.add(dayOffset + Duration(minutes: 10)),
        );
        expect(_acceptsDraft(q, d), true);
      });
      test('rejects yesterday', () {
        // Between midnight and day start
        // UTC: 2026-03-11 22:57:00.000Z | offset: 1.0 h, UTC: 2026-03-11 22:59:00.000Z | offset: 1.0 h
        final start = LocalDateTime.fromLocal(today.subtract(Duration(minutes: 3)));
        final end = LocalDateTime.fromLocal(today.subtract(Duration(minutes: 1)));

        // print("[S] range-start: ${q.toDbRange().startMs / 1000} | evt-end: ${end.localMillis / 1000}");
        // print(
        //   "[D] range-start: ${DateTime.fromMillisecondsSinceEpoch(q.toDbRange().startMs)} | evt-end: ${DateTime.fromMillisecondsSinceEpoch(end.localMillis)}",
        // );
        // print(
        //   "[D] range-start: ${DateTime.fromMillisecondsSinceEpoch(q.toDbRange().startMs)} | evt-end: ${end.asLocal} (aslocal)",
        // );
        expect(q.accepts(start, end), false);
      });
      test('rejects outside', () {
        /// Between midnight and day start
        final d = EvtDraft.inCurrentTZ(
          1,
          start: today.add(dayOffset - Duration(minutes: 3)),
          end: today.add(dayOffset - Duration(minutes: 1)),
        );
        expect(_acceptsDraft(q, d), false);
      });
      test('rejects overlapping', () {
        /// Start between midnight and day start
        final d = EvtDraft.inCurrentTZ(
          1,
          start: today.add(dayOffset - Duration(minutes: 3)),
          end: today.add(dayOffset + Duration(minutes: 10)),
        );
        expect(_acceptsDraft(q, d), false);
      });
    });

    group("toDb", () {
      test('day', () {
        final q = LocalTimeRangeQuery(
          dayOffset: dayOffset,
          ref: DateTime(2026, 3, 12), // thursday start (local)
          unit: GroupFreq.day,
        );
        final r = q.toDbRange();
        final dayStart = DateTime(2026, 3, 12);
      });
      test('week', () {
        final q = LocalTimeRangeQuery(
          dayOffset: dayOffset,
          ref: DateTime(2026, 3, 12, 15, 30), // thursday afternoon
          unit: GroupFreq.week,
        );
        final r = q.toDbRange();

        final weekStart = DateTime(2026, 3, 9); // monday start (local)

        final dtStart = DateTime.fromMillisecondsSinceEpoch(r.startMs);
        final dtEnd = DateTime.fromMillisecondsSinceEpoch(r.endMs);
      });
      test('month', () {
        final q = LocalTimeRangeQuery(
          dayOffset: dayOffset,
          ref: DateTime(2026, 3, 12),
          unit: GroupFreq.month,
        );
        final r = q.toDbRange();

        final monthStart = DateTime(2026, 3);

        final dtStart = DateTime.fromMillisecondsSinceEpoch(r.startMs);
        final dtEnd = DateTime.fromMillisecondsSinceEpoch(r.endMs);
      });
    });
  });
}
