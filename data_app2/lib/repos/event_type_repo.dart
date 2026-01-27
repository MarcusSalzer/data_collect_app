import 'package:data_app2/data/evt_type_rec.dart';
import 'package:data_app2/isar_models.dart';
import 'package:isar_community/isar.dart';

/// For accessing Event type data
class EventTypeRepo {
  final Isar _isar;

  EventTypeRepo(this._isar);

  Future<int> count() async {
    return await _isar.txn(() async {
      return await _isar.eventTypes.count();
    });
  }

  Future<List<EventType>> all() async {
    final evtTypes = await _isar.txn(() async {
      return await _isar.eventTypes.where().findAll();
    });

    return evtTypes;
  }

  /// get all existing typeId:s
  Future<Set<int>> allIds() async {
    return await _isar.txn(() async {
      return (await _isar.eventTypes.where().idProperty().findAll()).toSet();
    });
  }

  /// create and save new EventType
  Future<int> put(EvtTypeRec rec) async {
    return await _isar.writeTxn(() async {
      return await _isar.eventTypes.put(rec.toIsar());
    });
  }

  /// create and save new EventTypes
  Future<List<int>> putAll(Iterable<EvtTypeRec> recs) async {
    return await _isar.writeTxn(() async {
      return await _isar.eventTypes.putAll(recs.map((r) => r.toIsar()).toList());
    });
  }

  /// create and save new EventType, with name and defaults
  Future<int?> putWithId(int id, String name) async {
    return await _isar.writeTxn(() async {
      // skip if exists
      if (await _isar.eventTypes.where().idEqualTo(id).isNotEmpty()) {
        return null;
      }
      return await _isar.eventTypes.put(EventType(name)..id = id);
    });
  }

  /// create and save new EventTypes, without overwriting old Ids
  Future<List<int>> putIfNewId(Iterable<EvtTypeRec> recs) async {
    final addedIds = <int>[];

    // TODO: reimplement like in evtrepo (set diff ) instead??
    await _isar.writeTxn(() async {
      for (var r in recs) {
        // skip if exists
        final thisId = r.id;
        if (thisId != null && await _isar.eventTypes.where().idEqualTo(thisId).isNotEmpty()) {
          continue;
        }
        // add
        final addId = await _isar.eventTypes.put(r.toIsar());
        addedIds.add(addId);
      }
    });
    return addedIds;
  }

  /// Find an event type by id or name
  Future<EventType?> find({int? id, String? name}) async {
    return await _isar.txn(() async {
      if (id != null) {
        return await _isar.eventTypes.get(id);
      } else if (name != null) {
        return await _isar.eventTypes.where().nameEqualTo(name).findFirst();
      }
      return null;
    });
  }

  /// Get if exists, otherwise make a new
  Future<EventType> getOrCreate(String name) async {
    return await _isar.writeTxn(() async {
      final existing = await _isar.eventTypes.filter().nameEqualTo(name).findFirst();
      if (existing != null) {
        return existing;
      } else {
        final newType = EventType(name);
        await _isar.eventTypes.put(newType);
        return newType;
      }
    });
  }

  /// Delete all event types
  Future<int> deleteAll() async {
    final c = await _isar.eventTypes.count();

    await _isar.writeTxn(() async {
      _isar.eventTypes.clear();
    });

    return c;
  }

  Future<bool> delete(int id) async {
    return await _isar.writeTxn(() async {
      return _isar.eventTypes.delete(id);
    });
  }

  /// save or update EventType, returns id.
  Future<int> saveOrUpdateByName(EvtTypeRec rec) async {
    return await _isar.writeTxn(() async {
      final existing = await _isar.eventTypes.where().nameEqualTo(rec.name).findFirst();
      if (existing != null) {
        // give id to update instead of create
        rec.id = existing.id;
      }
      return await _isar.eventTypes.put(rec.toIsar());
    });
  }
}
