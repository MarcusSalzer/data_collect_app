import 'package:data_app2/contracts/data.dart';
import 'package:isar_community/isar.dart';

/// implements at least the basic operations
/// Operates on domain models [R] and draft models [Draft], works with isar collection of [I]
abstract class CrudRepo<R extends Identifiable, D extends Draft<R>, I> {
  CrudRepo(this.isar, {required this.draftToIsar, required this.recToIsar, required this.fromIsar});
  final Isar isar;

  /// Get the collection via Isar code-gen
  IsarCollection<I> get coll;

  /// Query selecting only the Id property.
  /// Must be a fresh QueryBuilder instance.
  QueryBuilder<I, int, QQueryOperations> get idProp;

  /// for persisting new objects
  final I Function(D) draftToIsar;

  /// for updating objects
  final I Function(R) recToIsar;

  /// for loading objects
  final R Function(I) fromIsar;

  // ====== Basic transactions ======

  /// Number of stored items
  Future<int> count() async {
    return await isar.txn(() async => await coll.count());
  }

  /// Get all (as domain models)
  Future<Iterable<R>> all() async {
    return (await isar.txn(() async => await coll.where().findAll())).map(fromIsar);
  }

  /// Get id:s
  Future<Set<int>> allIds() async {
    return await isar.txn(() async {
      return (await idProp.findAll()).toSet();
    });
  }

  /// Get a specific item, or null if missing
  Future<R?> getById(int id) async {
    final i = await isar.txn(() async => await coll.get(id));
    return (i != null) ? fromIsar(i) : null;
  }

  /// Create from draft, get new id.
  Future<int> create(D draft) async {
    return await isar.writeTxn(() async => await coll.put(draftToIsar(draft)));
  }

  /// create and save new EventTypes
  Future<List<int>> createAll(Iterable<D> drafts) async {
    return await isar.writeTxn(() async => await coll.putAll(drafts.map(draftToIsar).toList()));
  }

  /// update an item
  /// TODO Id should not change! throw error?
  Future<int> update(R rec) async {
    return await isar.writeTxn(() async => await coll.put(recToIsar(rec)));
  }

  /// create and save new EventTypes
  Future<List<int>> updateAll(Iterable<R> recs) async {
    return await isar.writeTxn(() async => await coll.putAll(recs.map(recToIsar).toList()));
  }

  /// Save Events to database, skip if the id already exists
  Future<List<int>> putIfNewId(Iterable<R> recs) async {
    return await isar.writeTxn(() async {
      // NOTE: not reusing allIds() query to prevent nested transactions
      // NOTE: important to use Set, so contains is fast
      final existing = (await idProp.findAll()).toSet();
      return await coll.putAll(recs.where((r) => !existing.contains(r.id)).map(recToIsar).toList());
    });
  }

  /// Delete all records, return deleted count
  Future<int> forceDeleteAll() async {
    final c = await coll.count();
    await isar.writeTxn(() async => await coll.clear());
    return c;
  }

  /// Delete a single record
  Future<bool> forceDelete(int id) async {
    return await isar.writeTxn(() async => await coll.delete(id));
  }
}
