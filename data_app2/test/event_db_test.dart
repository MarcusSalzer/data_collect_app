import 'package:data_app2/db_service.dart';
import 'package:data_app2/user_events.dart';
import 'package:isar/isar.dart';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  late Isar isar;

  setUp(() async {
    await Isar.initializeIsarCore(download: true);

    // Use a temporary directory for the test DB
    final dir = await Directory.systemTemp.createTemp();
    isar = await Isar.open(
      [EventSchema],
      directory: dir.path,
      name: 'test_db',
    );
  });

  tearDown(() async {
    await isar.close();
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
}
