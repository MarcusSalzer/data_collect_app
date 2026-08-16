import 'dart:collection';
import 'dart:math';

import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/util/colors.dart';

/// Boring, non-specific test data
class TestDummyData {
  static final rng = Random(42);

  static EvtDraft makeEvtDraft(int i, {int? locId}) {
    final t = DateTime.now().subtract(Duration(hours: 3 * i));
    return EvtDraft.inCurrentTZ(
      i,
      start: t,
      end: t.add(Duration(hours: 1, minutes: (10 * i) % 30)),
    )..locationId = locId;
  }

  static EvtTypeDraft makeEvtTypeDraft(int i) => EvtTypeDraft('type $i');

  static LocationDraft makeLocDraft(int i) =>
      LocationDraft('loc $i', rng.nextDouble() * 50 - 25, rng.nextDouble() * 50 - 25);

  /// Event category with rotating colors
  static EvtCatDraft makeEvtCatDraft(int i) {
    final colors = ColorEngine.defaults.values.toList();
    return EvtCatDraft('cat $i', colors[i % colors.length]);
  }

  /// Schema with [i] fields of rotating types and nullability
  static BlobSchemaDraft makeBlobSchemaDraft(int i) {
    final types = <BlobFieldType>[DInt(), DBool()];
    return BlobSchemaDraft(
      'bs $i',
      fields: Map.fromEntries(
        Iterable.generate(i, (id) => MapEntry("f $id", BlobFieldSpec(types[i % types.length], nullable: id % 2 == 0))),
      ),
    );
  }

  /// Schema with [i] fields of rotating types and nullability
  static UserBlobDraft makeBlobDraft(int i, BlobSchemaRec schema, List<String> enumValues) {
    return UserBlobDraft(
      i,
      eventId: (i % 2 == 0) ? i * 3 : null,
      values: {for (var MapEntry(key: k, value: spec) in schema.fields.entries) k: makeBlobValue(i, spec, enumValues)},
    );
  }

  /// get a single value (dynamic) that matches a field.
  static dynamic makeBlobValue(int i, BlobFieldSpec field, List<String> enumValues) {
    // half chance of nullable
    if (field.nullable && i % 2 == 1) {
      return null;
    }
    final v = switch (field.type) {
      DInt() => i,
      DDecimal() => i / 10,
      DText() => "text $i",
      DBool() => i % 3 == 1, // different cycle than null
      DDuration() => Duration(seconds: 5 * i).inMilliseconds,
      DEnum() => enumValues[i % enumValues.length],
      // make each child for a length i list.
      DArray a => List.generate(i, (j) => makeBlobValue(j, a.childType, enumValues)),
    };

    if (!field.isValid(v)) {
      throw StateError("$field does not accept $v");
    }

    return v;
  }

  /// Make a schema with one field per type.
  static BlobSchemaRec makeBlobSchemaAllTypes(
    UserEnumRec enumGroup, {
    bool nullable = false,
    int id = 137,
    EvtLinkSpec? evtLink,
  }) {
    // NOTE: we need to have all types here. With some default parameters.
    final fields = {
      "myInt": BlobFieldSpec(DInt(), nullable: nullable),
      "myDecimal": BlobFieldSpec(DDecimal(), nullable: nullable),
      "myText": BlobFieldSpec(DText(), nullable: nullable),
      "myBool": BlobFieldSpec(DBool(), nullable: nullable),
      "myDuration": BlobFieldSpec(DDuration(), nullable: nullable),
      // enum
      "myChoice": BlobFieldSpec(DEnum(enumGroup.name), nullable: nullable),
      // collections
      "myNumbers": BlobFieldSpec(DArray(BlobFieldSpec(DDecimal(), nullable: nullable)), nullable: nullable),
    };

    return BlobSchemaRec(
      id,
      name: "DummyAll",
      fields: fields,
      evtLink: evtLink,
    );
  }
}

/// Use [TestDummyData] to fill the DB with all kinds of data.
/// Records are created with ids that skip every [skipEveryId] value.
Future<void> fillDbWithDummyData(
  DBService db, {
  int nCats = 3,
  int nTypes = 15,
  int nEvts = 100,
  int nLocs = 7,
  int nEnums = 5,
  int skipEveryId = 4, // to leave gaps in auto-incrementing id:s.
}) async {
  // argument validation
  if (nEvts > 0) {
    if (nCats < 1) {
      throw ArgumentError("needs at least 1 category if we want events.");
    }
    if (nTypes < 1) {
      throw ArgumentError("needs at least 1 evt-type if we want events.");
    }
  }

  // blank slate DB
  await db.clear();

  // --- Categories ---
  await db.evtCats.updateAll(List.generate(nCats, (i) => TestDummyData.makeEvtCatDraft(i).toRec(i + i ~/ skipEveryId)));

  final catIds = (await db.evtCats.allIds()).toList();

  // --- Types (each linked to a valid category) ---
  await db.evtTypes.updateAll(
    List.generate(
      nTypes,
      (i) => (TestDummyData.makeEvtTypeDraft(i)..categoryId = catIds[i % catIds.length]).toRec(i + i ~/ skipEveryId),
    ),
  );

  final typeIds = (await db.evtTypes.allIds()).toList();

  // --- Locations ---
  await db.locations.updateAll(List.generate(nLocs, (i) => TestDummyData.makeLocDraft(i).toRec(i + i ~/ skipEveryId)));

  final locIds = (await db.locations.allIds()).toList();

  // --- Events (each linked to a valid type) ---
  final evtRecs = List.generate(
    nEvts,
    (i) =>
        (TestDummyData.makeEvtDraft(i)
              ..typeId = typeIds[i % typeIds.length]
              ..locationId = (i % 3 == 0 && locIds.isNotEmpty) ? locIds[i % locIds.length] : null)
            .toRec(i + i ~/ skipEveryId),
  );
  await db.evts.updateAll(evtRecs);

  final evtIds = (await db.evts.allIds()).toList();

  // --- enums ---
  await db.userEnums.updateAll(List.generate(nEnums, (i) => UserEnumDraft("enum $i").toRec(i + i ~/ skipEveryId)));

  final enumIds = (await db.userEnums.allIds()).toList();

  final evRecs = <UserEnumValueRec>[];
  // Make N values for the N:th enum
  for (var (idx, enumId) in enumIds.indexed) {
    for (var i = 0; i < idx; i++) {
      evRecs.add(
        UserEnumValueDraft(enumId, "E$enumId-V$i").toRec(i + i ~/ skipEveryId),
      );
    }
  }
  await db.userEnumValues.updateAll(evRecs);

  // some final validation
  if (await db.evts.count() != nEvts) {
    throw StateError("event count mismatch");
  }
  if (await db.evtTypes.count() != nTypes) {
    throw StateError("event type count mismatch");
  }
  if (await db.evtCats.count() != nCats) {
    throw StateError("event cat count mismatch");
  }
  if (await db.locations.count() != nLocs) {
    throw StateError("location count mismatch");
  }
  if (await db.userEnums.count() != nEnums) {
    throw StateError("enum count mismatch");
  }
}

/// Specific test data in relation to
/// Thu Jan  1 12:00:00 AM UTC 1970 (1970-01-01T00:00+00:00)
///
/// UTC   :wwww|tttttt
/// Local :wwwwww|w!tt
class SpecificEvtsFactory {
  final typeIds = {"before": 1, "after": 2, "simple": 3, "relative": 4};
  // Start of reference day
  final zeroUtcDt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  // day starts at setting
  final Duration dayStartOffset;
  final Duration tzOffset;

  LocalDateTime get zeroLocal => LocalDateTime.fromUtcAndOffset(zeroUtcDt, tzOffset).add(dayStartOffset);
  LocalDateTime get zeroUtc => LocalDateTime.fromUtcAndOffset(zeroUtcDt, tzOffset);
  SpecificEvtsFactory({required this.dayStartOffset, required this.tzOffset});

  List<EvtDraft> getTwoPerDay({required bool isLocal}) {
    final ref = isLocal ? zeroLocal : zeroUtc;

    final margin = Duration(minutes: 7);
    final dur = Duration(hours: 2);

    final inside = List.generate(7, (i) {
      final t0 = ref.add(Duration(days: i)).add(margin);
      return EvtDraft(typeIds["simple"]!, start: t0, end: t0.add(dur));
    });

    final overlapped = List.generate(7, (i) {
      final t0 = ref.add(Duration(days: i)).subtract(margin);
      return EvtDraft(typeIds["simple"]!, start: t0, end: t0.add(dur));
    });

    return inside + overlapped;
  }

  List<EvtDraft> getAllAroundBorder({required bool isLocal}) => [
    // exact
    before(isLocal: isLocal),
    after(isLocal: isLocal),
    // with margin
    before(isLocal: isLocal, margin: Duration(seconds: 1)),
    after(isLocal: isLocal, margin: Duration(seconds: 1)),
    // with overlap
    before(isLocal: isLocal, overlap: Duration(minutes: 13)),
    after(isLocal: isLocal, overlap: Duration(minutes: 13)),
  ];

  void _validate(Duration margin, Duration overlap, Duration length) {
    assert(margin < length);
    if (overlap > Duration.zero) {
      assert(margin < overlap);
    }
  }

  EvtDraft before({
    required bool isLocal,
    Duration margin = Duration.zero,
    Duration overlap = Duration.zero,
    Duration length = const Duration(hours: 4),
  }) {
    _validate(margin, overlap, length);
    final ref = isLocal ? zeroLocal : zeroUtc;
    return EvtDraft(
      typeIds["before"]!,
      start: ref.subtract(length),
      end: ref.subtract(margin).add(overlap), // close to border
    );
  }

  /// Event at [shift] from zero, and a length
  EvtDraft relative({required bool isLocal, required Duration shift, Duration length = const Duration(hours: 4)}) {
    final ref = isLocal ? zeroLocal : zeroUtc;
    return EvtDraft(
      typeIds["relative"]!,
      start: ref.add(shift),
      end: ref.add(shift + length),
    );
  }

  /// Event after midninght/daystart
  EvtDraft after({
    required bool isLocal,
    Duration margin = Duration.zero,
    Duration overlap = Duration.zero,
    Duration length = const Duration(hours: 4),
  }) {
    _validate(margin, overlap, length);
    final ref = isLocal ? zeroLocal : zeroUtc;

    return EvtDraft(
      typeIds["after"]!,
      start: ref.subtract(overlap).add(margin), // close to border
      end: ref.add(length),
    );
  }
}

class SimpleDummyData {
  static UnmodifiableListView<EvtTypeRec> getDummyEvtTypes() =>
      UnmodifiableListView([EvtTypeRec(1, "type A"), EvtTypeRec(2, "type B"), EvtTypeRec(3, "type C")]);

  static UnmodifiableListView<EvtCatRec> getDummyEvtCats() =>
      UnmodifiableListView([EvtCatRec(1, "other"), EvtCatRec(1, "cat A"), EvtCatRec(3, "cat b")]);
}

/// Get a map of {repoName: idSet}
Future<Map<String, Set<int>>> getAllRepoIds(DBService db) async => Map.fromEntries(
  await Future.wait(db.allRepos.map((r) async => MapEntry(r.runtimeType.toString(), await r.allIds()))),
);
