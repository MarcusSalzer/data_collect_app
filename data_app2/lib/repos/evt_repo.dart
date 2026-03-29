import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:isar_community/isar.dart';

class EvtRepo extends CrudRepo<EvtRec, EvtDraft, Event> {
  EvtRepo(super.isar)
    : super(
        draftToIsar: (d) => Event(
          typeId: d.typeId,
          startLocalMillis: d.start?.localMillis,
          startUtcMillis: d.start?.utcMillis,
          endLocalMillis: d.end?.localMillis,
          endUtcMillis: d.end?.utcMillis,
        ),
        recToIsar: (r) => Event(
          typeId: r.typeId,
          startLocalMillis: r.start?.localMillis,
          startUtcMillis: r.start?.utcMillis,
          endLocalMillis: r.end?.localMillis,
          endUtcMillis: r.end?.utcMillis,
        )..id = r.id,
        fromIsar: (i) => EvtRec(
          i.id,
          i.typeId,
          start: LocalDateTime.maybeFromMillis(i.startUtcMillis, i.startLocalMillis),
          end: LocalDateTime.maybeFromMillis(i.endUtcMillis, i.endLocalMillis),
        ),
      );

  @override
  get coll => isar.events;
  @override
  get idProp => isar.events.where().idProperty();

  /// get all referenced typeId:s on events
  Future<Set<int>> allReferencedTypeIds() async {
    return await isar.txn(() async {
      return (await isar.events.where().typeIdProperty().findAll()).toSet();
    });
  }

  /// Get some events.
  Future<Iterable<EvtRec>> filteredUtcTime(UtcDbTimeRange range, {Iterable<int>? typeIds}) async {
    final evts = await isar.txn(() async {
      final f = coll
          .where()
          .optional(typeIds != null, (q) => q.anyOf(typeIds!, (q, int n) => q.typeIdEqualTo(n)))
          .filter();

      // NO index
      return (switch (range.overlap) {
        OverlapMode.fullyInside =>
          f.startUtcMillisGreaterThan(range.startMs, include: true).endUtcMillisLessThan(range.endMs, include: false),
        OverlapMode.endInside =>
          f.endUtcMillisGreaterThan(range.startMs, include: true).endUtcMillisLessThan(range.endMs, include: false),
        OverlapMode.overlapping =>
          f.startUtcMillisLessThan(range.endMs, include: false).endUtcMillisGreaterThan(range.startMs, include: true),
      }).sortByStartUtcMillis().findAll();
    });
    return evts.map(fromIsar);
  }

  /// Get some events.
  Future<Iterable<EvtRec>> filteredLocalTime(
    LocalDbTimeRange range, {
    Iterable<int>? typeIds,
  }) async {
    final evts = await isar.txn(() async {
      final f = coll.where();

      // uses index
      return (switch (range.overlap) {
            OverlapMode.fullyInside =>
              f
                  .startLocalMillisGreaterThan(range.startMs, include: true)
                  .filter()
                  .endLocalMillisLessThan(range.endMs, include: false),

            OverlapMode.endInside =>
              f
                  .endLocalMillisGreaterThan(range.startMs, include: true)
                  .filter()
                  .endLocalMillisLessThan(range.endMs, include: false),

            OverlapMode.overlapping =>
              f
                  .startLocalMillisLessThan(range.endMs, include: false)
                  .filter()
                  .endLocalMillisGreaterThan(range.startMs, include: true),
          })
          .optional(typeIds != null, (q) => q.anyOf(typeIds!, (q, int n) => q.typeIdEqualTo(n)))
          .sortByStartLocalMillis()
          .findAll();
    });
    return evts.map(fromIsar);
  }

  /// Get some events.
  Future<Iterable<EvtRec>> filteredTypes(Iterable<int> typeIds) async {
    final evts = await isar.txn(
      () async => await coll.where().anyOf(typeIds, (q, int n) => q.typeIdEqualTo(n)).findAll(),
    );
    return evts.map(fromIsar);
  }

  /// Get some events.
  @Deprecated("use new range api")
  Future<Iterable<EvtRec>> filteredLocalTimeOld({
    Iterable<int>? typeIds,
    LocalDateTime? earliest,
    LocalDateTime? latest,
  }) async {
    final evts = await isar.txn(
      () async => await coll
          // sort reverse chrono
          .where(sort: Sort.desc)
          // optinally filter by time range
          .optional(earliest != null, (q) => q.startLocalMillisGreaterThan(earliest!.localMillis, include: true))
          .filter()
          .optional(latest != null, (q) => q.endLocalMillisLessThan(latest!.localMillis))
          // optionally filter by evt type
          .optional(typeIds != null, (q) => q.anyOf(typeIds!, (q, int n) => q.typeIdEqualTo(n)))
          .findAll(),
    );
    return evts.map(fromIsar);
  }

  Future<EvtRec?> oldest() async {
    final i = await isar.txn(() async => await coll.where(sort: Sort.asc).anyStartLocalMillis().findFirst());
    return (i == null) ? null : fromIsar(i);
  }

  /// latest events (chronological order)
  Future<Iterable<EvtRec>> latest(int? count) async {
    return (await isar.txn(
      () async => await coll
          // Desc to get latest -> reverse back later
          .where(sort: Sort.desc)
          .anyStartLocalMillis()
          .optional(count != null, (q) => q.limit(count!))
          .findAll(),
    )).reversed.map(fromIsar);
  }
}
