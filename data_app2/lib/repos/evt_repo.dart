import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/local_datetime.dart';
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
  Future<Iterable<EvtRec>> filteredLocalTime({
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

  /// reverse chronological events
  Future<Iterable<EvtRec>> latest(int? count) async {
    return (await isar.txn(
      () async => await coll
          .where(sort: Sort.desc)
          .anyStartLocalMillis()
          .optional(count != null, (q) => q.limit(count!))
          .findAll(),
    )).map(fromIsar);
  }
}
