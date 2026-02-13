import 'package:data_app2/data/evt.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/dummy_data.dart';

/// Get matching events, and check that retrieved/rejected match accept()
Future<Iterable<EvtRec>> _getEvtsCheckQuery(DBService db, TimeRangeQuery q) async {
  final evts = switch (q) {
    UtcTimeRangeQuery() => await db.evts.filteredUtcTime(range: q.toDbRange()),
    LocalTimeRangeQuery() => await db.evts.filteredLocalTime(range: q.toDbRange()),
  };
  final includedIds = evts.map((e) => e.id).toSet();
  final rejected = (await db.evts.all()).where((e) => !includedIds.contains(e.id));

  for (var e in evts) {
    expect(q.accepts(e.start!, e.end!), true, reason: "should accept $e. (${e.start!.utcMillis}-${e.end!.utcMillis})");
  }
  for (var e in rejected) {
    expect(q.accepts(e.start!, e.end!), false, reason: "should reject $e. (${e.start!.utcMillis}-${e.end!.utcMillis})");
  }

  return evts;
}

void main() {
  late final DBService db;
  setUpAll(() async {
    db = await getDummyDb();
  });

  group("Filtered UTC", () {
    group('Low level', () {
      setUpAll(() async {
        await db.evts.forceDeleteAll();
        await db.isar.writeTxn(() async {
          await db.evts.coll.put(
            Event(typeId: 1, startLocalMillis: 100, endLocalMillis: 200, startUtcMillis: 50, endUtcMillis: 150),
          );
        });
      });
      test('inside (various ranges)', () async {
        /// Query closure
        Future<Iterable<EvtRec>> get(int rs, int re) async =>
            await db.evts.filteredUtcTime(range: UtcTimeRange(rs, re, OverlapMode.fullyInside));

        // in
        expect((await get(49, 151)).length, 1);
        // over range start
        expect((await get(51, 151)).length, 0);
        // over range end
        expect((await get(10, 51)).length, 0);
        // after range (completely outside)
        expect((await get(10, 49)).length, 0);
        // after range (touches range end)
        expect((await get(10, 50)).length, 0);
        // before range (completely outside)
        expect((await get(151, 2000)).length, 0);
        // before range (touches range start)
        expect((await get(150, 2000)).length, 0);
      });
      test('overlap (various ranges)', () async {
        /// Query closure
        Future<Iterable<EvtRec>> get(int rs, int re) async =>
            await db.evts.filteredUtcTime(range: UtcTimeRange(rs, re, OverlapMode.overlapping));

        // in
        expect((await get(49, 151)).length, 1);
        // over range start
        expect((await get(51, 151)).length, 1);
        // over range end
        expect((await get(10, 51)).length, 1);
        // after range (completely outside)
        expect((await get(10, 49)).length, 0);
        // after range (touches range end)
        expect((await get(10, 50)).length, 0);
        // before range (completely outside)
        expect((await get(151, 2000)).length, 0);
        // before range (touches range start)
        expect((await get(150, 2000)).length, 1);
      });
    });

    group('Using RangeQuery class', () {
      final factory = SpecificEvtsFactory(dayStartOffset: Duration.zero, tzOffset: Duration(hours: 3));

      group('simple', () {
        setUpAll(() async {
          final drafts = factory.getTwoPerDay(isLocal: false);

          await db.evts.forceDeleteAll();
          await db.evts.createAll(drafts);
        });
        test('day (fully inside)', () async {
          final q = UtcTimeRangeQuery(
            referenceUtc: factory.zeroUtcDt.add(Duration(days: 1)),
            unit: GroupFreq.day,
            overlapMode: OverlapMode.fullyInside,
          );
          final evts = await db.evts.filteredUtcTime(range: q.toDbRange());

          expect(evts.length, 1);
        });
        test('day (overlap)', () async {
          final q = UtcTimeRangeQuery(
            referenceUtc: factory.zeroUtcDt.add(Duration(days: 1)),
            unit: GroupFreq.day,
            overlapMode: OverlapMode.overlapping,
          );

          final evts = await db.evts.filteredUtcTime(range: q.toDbRange());

          /// night before, today, next night
          expect(evts.length, 3);
        });
      });

      group('around border', () {
        final factory = SpecificEvtsFactory(dayStartOffset: Duration.zero, tzOffset: Duration(hours: 3));
        setUpAll(() async {
          final drafts = factory.getAllAroundBorder(isLocal: false);

          await db.clear();
          await db.evts.createAll(drafts);
        });
        test("get before midnight (fully inside)", () async {
          final q = UtcTimeRangeQuery(
            referenceUtc: factory.zeroUtcDt.subtract(Duration(days: 1)),
            unit: GroupFreq.day,
            overlapMode: OverlapMode.fullyInside,
          );
          expect(q.toString(), "(1969-12-31 00:00:00.000Z, 1970-01-01 00:00:00.000Z) fullyInside");
          expect(
            q.toDbRange(),
            UtcTimeRange(DateTime.parse("1969-12-31 00:00:00.000Z").millisecondsSinceEpoch, 0, OverlapMode.fullyInside),
          );

          final evts = await _getEvtsCheckQuery(db, q);

          expect(evts.length, 1);
        });

        test("get before midnight (with overlap)", () async {
          final q = UtcTimeRangeQuery(
            referenceUtc: factory.zeroUtcDt.subtract(Duration(days: 1)),
            unit: GroupFreq.day,
            overlapMode: OverlapMode.overlapping,
          );
          expect(q.toString(), "(1969-12-31 00:00:00.000Z, 1970-01-01 00:00:00.000Z) overlapping");

          final evts = await _getEvtsCheckQuery(db, q);

          expect(evts.length, 4);
        });
      });
    });
  });
  group('Filtered LOCAL', () {
    group('Low level', () {
      setUpAll(() async {
        await db.evts.forceDeleteAll();
        await db.isar.writeTxn(() async {
          await db.evts.coll.put(
            Event(typeId: 1, startLocalMillis: 50, endLocalMillis: 150, startUtcMillis: 100, endUtcMillis: 200),
          );
        });
      });
      test('inside (various ranges)', () async {
        /// Query closure
        Future<Iterable<EvtRec>> get(int rs, int re) async =>
            await db.evts.filteredLocalTime(range: LocalTimeRange(rs, re, OverlapMode.fullyInside));

        // in
        expect((await get(49, 151)).length, 1);
        // over range start
        expect((await get(51, 151)).length, 0);
        // over range end
        expect((await get(10, 51)).length, 0);
        // after range (completely outside)
        expect((await get(10, 49)).length, 0);
        // after range (touches range end)
        expect((await get(10, 50)).length, 0);
        // before range (completely outside)
        expect((await get(151, 2000)).length, 0);
        // before range (touches range start)
        expect((await get(150, 2000)).length, 0);
      });
      test('overlap (various ranges)', () async {
        /// Query closure
        Future<Iterable<EvtRec>> get(int rs, int re) async =>
            await db.evts.filteredLocalTime(range: LocalTimeRange(rs, re, OverlapMode.overlapping));

        // in
        expect((await get(49, 151)).length, 1);
        // over range start
        expect((await get(51, 151)).length, 1);
        // over range end
        expect((await get(10, 51)).length, 1);
        // after range (completely outside)
        expect((await get(10, 49)).length, 0);
        // after range (touches range end)
        expect((await get(10, 50)).length, 0);
        // before range (completely outside)
        expect((await get(151, 2000)).length, 0);
        // before range (touches range start)
        expect((await get(150, 2000)).length, 1);
      });
    });
  });
}
