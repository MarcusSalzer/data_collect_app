import 'package:data_app2/isar_models.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:isar_community/isar.dart';

/// For accessing Event data
class EventRepo {
  final Isar _isar;

  EventRepo(this._isar);

  Future<int> count() async {
    return await _isar.txn(() async {
      return await _isar.events.count();
    });
  }

  /// get all event id:s from db
  Future<Set<int>> allIds() async {
    return await _isar.txn(() async {
      return (await _isar.events.where().idProperty().findAll()).toSet();
    });
  }

  /// get all events from db
  Future<List<Event>> all() async {
    return await _isar.txn(() async {
      return await _isar.events.where().findAll();
    });
  }

  /// get all referenced typeId:s on events
  Future<Set<int>> allReferencedTypeIds() async {
    return await _isar.txn(() async {
      return (await _isar.events.where().typeIdProperty().findAll()).toSet();
    });
  }

  /// Get one (first) event
  Future<Event?> getOne() async {
    return await _isar.txn(() async {
      return await _isar.events.where().anyId().findFirst();
    });
  }

  Future<bool> delete(int id) async {
    return await _isar.writeTxn(() async {
      return _isar.events.delete(id);
    });
  }

  /// Save a new or updated event
  ///
  /// returns: id.
  Future<int> put(Event evt) async {
    return await _isar.writeTxn(() async {
      return _isar.events.put(evt);
    });
  }

  /// reverse chronological events
  Future<List<Event>> latest(int? count) async {
    return await _isar.txn(() async {
      return _isar.events
          .where(sort: Sort.desc)
          .anyStartLocalMillis()
          .optional(count != null, (q) => q.limit(count!))
          .findAll();
    });
  }

  /// Save Events to database
  Future<int> putAll(List<Event> data) async {
    final c = await _isar.writeTxn(() async {
      final ids = await _isar.events.putAll(data);
      return ids.length;
    });
    return c;
  }

  /// Save Events to database, skip if the id already exists
  Future<int> putIfNewId(Iterable<Event> recs) async {
    final c = await _isar.writeTxn(() async {
      // skip existing ids
      final existing = (await _isar.events.where().idProperty().findAll())
          .toSet();
      final ids = await _isar.events.putAll(
        recs.where((r) => !existing.contains(r.id)).toList(),
      );
      return ids.length;
    });
    return c;
  }

  /// Save [EvtDrafts]s to database
  // Future<int> importEvtDraftsDB(List<EvtDraft> data) async {
  //   final c = await _isar.writeTxn(() async {
  //     final ids = await _isar.events.putAll(data);
  //     return ids.length;
  //   });
  //   return c;
  // }

  /// Delete all events
  Future<int> deleteAll() async {
    final c = await _isar.events.count();

    await _isar.writeTxn(() async {
      _isar.events.clear();
    });

    return c;
  }

  /// Get some events.
  Future<List<Event>> filteredLocalTime({
    Iterable<int>? typeIds,
    LocalDateTime? earliest,
    LocalDateTime? latest,
  }) async {
    final evts = await _isar.txn(() async {
      return _isar.events
          // sort reverse chrono
          .where(sort: Sort.desc)
          // optinally filter by time range
          .optional(
            earliest != null,
            (q) => q.startLocalMillisGreaterThan(
              earliest!.localMillis,
              include: true,
            ),
          )
          .filter()
          .optional(
            latest != null,
            (q) => q.endLocalMillisLessThan(latest!.localMillis),
          )
          // optionally filter by evt type
          .optional(
            typeIds != null,
            (q) => q.anyOf(typeIds!, (q, int n) => q.typeIdEqualTo(n)),
          )
          .findAll();
    });
    return evts;
  }
}
