import 'package:data_app2/db_service.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/user_events.dart';
import 'package:isar_community/isar.dart';

import 'package:test/test.dart';

import 'test_util/dummy_app.dart';

void main() {
  late final Isar isar;
  late final DBService db;

  setUpAll(() async {
    isar = await getTmpIsar();
    db = DBService(isar);
  });

  tearDownAll(() async {
    await isar.close();
  });

  // Clear DB between tests
  setUp(() async {
    await isar.writeTxn(() async {
      await isar.clear(); // clears all collections
    });
  });

  test('save and load Event', () async {
    final start = DateTime(2025, 8, 19, 1, 0);
    final end = DateTime(2025, 8, 19, 3, 0);

    final localOffset = start.timeZoneOffset;

    // create a new event
    final evtRec = EvtRec.inCurrentTZ(
      id: null,
      typeId: 42,
      start: start,
      end: end,
    );

    // Convert to Isar object
    final evtIsar = evtRec.toIsar();

    final evtOffset = Duration(
      milliseconds: evtIsar.startLocalMillis! - evtIsar.startUtcMillis!,
    );

    expect(evtOffset, localOffset);
    expect(evtRec.start?.offsetMillis, localOffset.inMilliseconds);

    // Save to DB
    await isar.writeTxn(() async {
      await isar.events.put(evtIsar);
    });

    // Load from DB
    final loadedIsar = await isar.events.get(evtIsar.id);
    expect(loadedIsar, isNotNull);
    if (loadedIsar == null) throw Exception("should exist in DB");

    // Convert back
    final loadedRec = EvtRec.fromIsar(loadedIsar);

    // type id
    expect(loadedRec.typeId, evtRec.typeId);
    //  timestamps
    expect(loadedRec.start, evtRec.start, reason: "Start?");
    expect(loadedRec.end, evtRec.end, reason: "End?");
  });

  group('[Query]', () {
    test('Get events in local-time range', () async {
      final tzoMs = 7_200_000; // two hours

      final midnight = LocalDateTime.fromUtcISOAndffset(
        utcIso: '2025-05-01T22:00:00Z',
        offsetMillis: tzoMs,
      );

      // should be in first day
      final lastNight = EvtRec(
        id: 787843,
        typeId: 1,
        start: LocalDateTime.fromUtcISOAndffset(
          utcIso: '2025-05-01T21:30:00Z',
          offsetMillis: tzoMs,
        ),
        end: LocalDateTime.fromUtcISOAndffset(
          utcIso: '2025-05-01T21:55:00Z',
          offsetMillis: tzoMs,
        ),
      );

      // accross midnight, shouldnt count to either day
      final across = EvtRec(
        id: 787844,
        typeId: 3,
        start: LocalDateTime.fromUtcISOAndffset(
          utcIso: '2025-05-01T21:30:00Z',
          offsetMillis: tzoMs,
        ),
        end: LocalDateTime.fromUtcISOAndffset(
          utcIso: '2025-05-01T22:01:00Z',
          offsetMillis: tzoMs,
        ),
      );

      // should be in second day
      final earlyMorning = EvtRec(
        id: 3389,
        typeId: 2,
        start: LocalDateTime.fromUtcISOAndffset(
          utcIso: '2025-05-01T22:30:00Z',
          offsetMillis: tzoMs,
        ),
        end: LocalDateTime.fromUtcISOAndffset(
          utcIso: '2025-05-01T22:55:00Z',
          offsetMillis: tzoMs,
        ),
      );

      // Save to DB
      await isar.writeTxn(() async {
        await isar.events.put(lastNight.toIsar());
        await isar.events.put(across.toIsar());
        await isar.events.put(earlyMorning.toIsar());
      });

      // get all events for each day
      final firstDay = await db.events.filteredLocalTime(latest: midnight);
      final secondDay = await db.events.filteredLocalTime(earliest: midnight);

      expect(firstDay.length, 1, reason: "Should be 1 event first day");
      expect(EvtRec.fromIsar(firstDay[0]), lastNight);
      expect(secondDay.length, 1, reason: "Should be 1 event second day");
      expect(EvtRec.fromIsar(secondDay[0]), earlyMorning);
    });
  });
}
