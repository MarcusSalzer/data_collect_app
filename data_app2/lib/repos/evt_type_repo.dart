import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/errors/db_ref_exists_error.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';
import 'package:isar_community/isar.dart';

/// For accessing Event type data
class EvtTypeRepo extends CrudRepo<EvtTypeRec, EvtTypeDraft, EventType> {
  EvtTypeRepo(super.isar)
    : super(
        // NOTE: trim names to avoid confusing uniqueness issues
        draftToIsar: (d) => EventType(d.name.trim(), d.categoryId),
        recToIsar: (r) => EventType(r.name.trim(), r.categoryId)..id = r.id,
        fromIsar: (i) => EvtTypeRec(i.id, i.name, i.categoryId),
      );

  @override
  get coll => isar.eventTypes;
  @override
  get idProp => isar.eventTypes.where().idProperty();

  // === More specific transactions ===

  Future<Iterable<EvtTypeRec>> subset(Iterable<int> getIds) async {
    final evtTypes = await isar.txn(() async {
      return await coll.where().anyOf(getIds, (et, q) => et.idEqualTo(q)).findAll();
    });

    return evtTypes.map(fromIsar);
  }

  /// Find an event type by id or name
  Future<EvtTypeRec?> findByName(String name) async {
    final i = await isar.txn(() async => await coll.where().nameEqualTo(name).findFirst());
    return (i != null) ? fromIsar(i) : null;
  }

  /// Get if exists, otherwise make a new
  Future<EvtTypeRec> getOrCreate(String name) async {
    return await isar.writeTxn(() async {
      final existing = await isar.eventTypes.where().nameEqualTo(name).findFirst();
      if (existing != null) {
        return fromIsar(existing);
      } else {
        final newType = EventType(name);
        await isar.eventTypes.put(newType);
        return fromIsar(newType);
      }
    });
  }

  /// Delete a event type, throws [DbRefExistsError] if it is referenced by some EvtType
  Future<bool> deleteIfUnreferenced(int id) async {
    // No index here yet. eventTypes is not huge so should be ok.
    if (await isar.events.filter().typeIdEqualTo(id).findFirst() != null) {
      throw DbRefExistsError(id);
    }
    return await super.forceDelete(id);
  }

  /// Get all types in a category
  Future<Iterable<EvtTypeRec>> inCategory(int catId) async {
    final types = await isar.txn(() async {
      return await coll.filter().categoryIdEqualTo(catId).findAll();
    });
    return types.map(fromIsar);
  }

  /// Remove category from a type
  Future<void> unlinkCategory(EvtTypeRec rec) async {
    await isar.writeTxn(() async {
      final updated = recToIsar(rec)..categoryId = EvtCatRepo.defaultId;
      await coll.put(updated);
    });
  }
}
