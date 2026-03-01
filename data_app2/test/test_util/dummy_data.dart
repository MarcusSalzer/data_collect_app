import 'dart:collection';

import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/util/colors.dart';

/// Boring, non-specific test data
class TestDummyData {
  static EvtDraft makeEvtDraft(int i) => EvtDraft.inCurrentTZ(
    i,
    start: DateTime(2024, 1, 1).add(Duration(days: i)),
    end: DateTime(2024, 1, 2).add(Duration(days: i)),
  );

  static EvtTypeDraft makeEvtTypeDraft(int i) => EvtTypeDraft('type $i');

  static EvtCatDraft makeEvtCatDraft(int i) {
    final colors = ColorEngine.defaults.values.toList();
    return EvtCatDraft('cat $i', colors[i % colors.length]);
  }
}

Future<({List<int> catIds, List<int> evtIds, List<int> typeIds})> fillDbWithDummyData(
  DBService db, {
  int nCats = 3,
  int nTypes = 5,
  int nEvts = 20,
}) async {
  // ---- Categories ----
  final catDrafts = List.generate(nCats, TestDummyData.makeEvtCatDraft);
  final catIds = await db.evtCats.createAll(catDrafts);

  // ---- Types (each linked to a valid category) ----
  final typeDrafts = List.generate(
    nTypes,
    (i) => TestDummyData.makeEvtTypeDraft(i)..categoryId = catIds[i % catIds.length],
  );

  final typeIds = await db.evtTypes.createAll(typeDrafts);

  // ---- Events (each linked to a valid type) ----
  final evtDrafts = List.generate(nEvts, (i) => TestDummyData.makeEvtDraft(i)..typeId = typeIds[i % typeIds.length]);

  final evtIds = await db.evts.createAll(evtDrafts);
  return (evtIds: evtIds, typeIds: typeIds, catIds: catIds);
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

  EvtDraft relative({required bool isLocal, required Duration shift, Duration length = const Duration(hours: 4)}) {
    final ref = isLocal ? zeroLocal : zeroUtc;
    return EvtDraft(
      typeIds["relative"]!,
      start: ref.add(shift),
      end: ref.add(shift + length), // close to border
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
