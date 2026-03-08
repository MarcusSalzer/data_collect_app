import 'package:data_app2/db_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_util/dummy_app.dart';
import '../test_util/dummy_data.dart';

void main() {
  late final DBService db;
  setUpAll(() async {
    db = await getDummyDb();
  });
  setUp(() async {
    // clear db between tests
    await db.clear();
  });
  group('createIfPossible', () {
    test('creates All', () async {
      final oldDrafts = List.generate(5, (i) => TestDummyData.makeEvtCatDraft(i));
      final newDrafts = List.generate(3, (i) => TestDummyData.makeEvtCatDraft(i + 5));
      await db.evtCats.createAll(oldDrafts);
      final nSkip = await db.evtCats.createIfPossible(newDrafts);
      expect(nSkip, 0);

      expect(await db.evtCats.count(), 8);
    });
    test('creates subset', () async {
      final oldDrafts = List.generate(3, (i) => TestDummyData.makeEvtCatDraft(i)); // 0,1,2
      final newDrafts = List.generate(3, (i) => TestDummyData.makeEvtCatDraft(i + 1)); // 1,2,3
      await db.evtCats.createAll(oldDrafts);
      final nSkip = await db.evtCats.createIfPossible(newDrafts);
      expect(nSkip, 2); // 2 are overlapping

      expect(await db.evtCats.count(), 4);
    });
  });
}
