import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/isar_models.dart';
import 'package:test/test.dart';

import 'test_util/dummy_app.dart';
import 'test_util/dummy_data.dart';

void runCrudRepoTests<R extends Identifiable, D extends Draft<R>, I>({
  required CrudRepo<R, D, I> Function() repo,
  required D Function(int seed) makeDraft,
  required void Function(R actual, R match) expectEqual, //NOTE: should call expect()
}) {
  late CrudRepo<R, D, I> r;

  setUp(() async {
    r = repo();
    await r.forceDeleteAll();
  });

  test('starts empty', () async {
    expect(await r.count(), 0);
  });

  test('insert and fetch by id', () async {
    final draft = makeDraft(1);
    final id = await r.create(draft);
    final rec = await r.getById(id);
    expect(rec, isNotNull);

    expectEqual(rec!, draft.toRec(id));
  });

  test('all() returns inserted items', () async {
    final ids = <int>[];

    for (var i = 0; i < 3; i++) {
      ids.add(await r.create(makeDraft(i)));
    }

    expect((await r.all()).toList().length, ids.length);
  });

  test('can clear everything', () async {
    await r.create(makeDraft(1));
    await r.forceDeleteAll();

    expect(await r.count(), 0);
  });
}

void main() {
  late DBService db;

  setUpAll(() async {
    db = DBService(await getTmpIsar());
  });

  group('EvtRepo', () {
    runCrudRepoTests<EvtRec, EvtDraft, Event>(
      repo: () => db.events,
      makeDraft: TestDummyData.makeEvtDraft,
      expectEqual: (actual, match) => expect(actual, match), // use equality op
    );
  });
  group('EvtTypeRepo', () {
    runCrudRepoTests<EvtTypeRec, EvtTypeDraft, EventType>(
      repo: () => db.eventTypes,
      makeDraft: TestDummyData.makeEvtTypeDraft,
      expectEqual: (a, b) {
        expect(a.id, b.id);
        expect(a.name, b.name, reason: "name");
        expect(a.color, b.color);
        expect(a.categoryId, b.categoryId, reason: "category Id");
      },
    );
  });
  group('EvtCatRepo', () {
    runCrudRepoTests<EvtCatRec, EvtCatDraft, EventCategory>(
      repo: () => db.categories,
      makeDraft: TestDummyData.makeEvtCatDraft,
      expectEqual: (a, b) {
        expect(a.id, b.id);
        expect(a.name, b.name);
      },
    );
  });
}
