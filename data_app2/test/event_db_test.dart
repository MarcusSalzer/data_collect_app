import 'package:data_app2/data/evt.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/local_datetime.dart';
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
    final dr = EvtDraft.inCurrentTZ(42, start: start, end: end);

    // Convert to Isar object

    final evtOffset = Duration(milliseconds: dr.start!.localMillis - dr.start!.utcMillis);

    expect(evtOffset, localOffset);
    expect(dr.start?.offsetMillis, localOffset.inMilliseconds);

    // Save to DB
    final id = await db.events.create(dr);

    // Load from DB
    final loaded = await db.events.getById(id);
    expect(loaded, isNotNull);
    if (loaded == null) throw Exception("should exist in DB");

    // type id
    expect(loaded.typeId, dr.typeId);
    //  timestamps
    expect(loaded.start, dr.start, reason: "Start?");
    expect(loaded.end, dr.end, reason: "End?");
  });

  group('[Query]', () {
    test('Get events in local-time range', () async {
      final tzoMs = 7_200_000; // two hours

      final midnight = LocalDateTime.fromUtcISOAndffset(utcIso: '2025-05-01T22:00:00Z', offsetMillis: tzoMs);

      // should be in first day
      final lastNight = EvtRec(
        787843,
        1,
        start: LocalDateTime.fromUtcISOAndffset(utcIso: '2025-05-01T21:30:00Z', offsetMillis: tzoMs),
        end: LocalDateTime.fromUtcISOAndffset(utcIso: '2025-05-01T21:55:00Z', offsetMillis: tzoMs),
      );

      // accross midnight, shouldnt count to either day
      final across = EvtRec(
        787844,
        3,
        start: LocalDateTime.fromUtcISOAndffset(utcIso: '2025-05-01T21:30:00Z', offsetMillis: tzoMs),
        end: LocalDateTime.fromUtcISOAndffset(utcIso: '2025-05-01T22:01:00Z', offsetMillis: tzoMs),
      );

      // should be in second day
      final earlyMorning = EvtRec(
        3389,
        2,
        start: LocalDateTime.fromUtcISOAndffset(utcIso: '2025-05-01T22:30:00Z', offsetMillis: tzoMs),
        end: LocalDateTime.fromUtcISOAndffset(utcIso: '2025-05-01T22:55:00Z', offsetMillis: tzoMs),
      );

      // Save to DB
      await db.events.updateAll([lastNight, across, earlyMorning]);

      // get all events for each day
      final firstDay = (await db.events.filteredLocalTime(latest: midnight)).toList();
      final secondDay = (await db.events.filteredLocalTime(earliest: midnight)).toList();

      expect(firstDay.length, 1, reason: "Should be 1 event first day");
      expect(firstDay[0], lastNight);
      expect(secondDay.length, 1, reason: "Should be 1 event second day");
      expect(secondDay[0], earlyMorning);
    });
  });
}
