import 'package:data_app2/data/evt_type_rec.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/isar_models.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Handle caching/storing and resolves types from id and name etc.
class EvtTypeManager extends ChangeNotifier {
  // Store both maps for fast lookup
  Map<String, EvtTypeRec> _byName = {};
  Map<int, EvtTypeRec> _byId = {};

  /// optionally fill with types
  /// Note: only provided types with id will be included
  EvtTypeManager({Iterable<EvtTypeRec>? types}) {
    if (types != null) {
      for (var t in types) {
        final tId = t.id;
        if (tId != null) {
          _byName[t.name] = t;
          _byId[tId] = t;
        }
      }
    }
  }

  List<EvtTypeRec> get all => _byId.values.toList();

  /// Reset cache and fill
  void reloadFromIsar(Iterable<EventType> evtTypes) {
    _byName = {};
    _byId = {};
    for (var et in evtTypes) {
      final rec = EvtTypeRec.fromIsar(et);
      _byName[et.name] = rec;
      _byId[et.id] = rec;
    }
    notifyListeners();
  }

  /// add a single type
  void add(int id, EvtTypeRec rec) {
    rec.id = id;
    _byName[rec.name] = rec;
    _byId[id] = rec;
    notifyListeners();
  }

  /// Resolve type from cache only, return null if missing.
  EvtTypeRec? resolveById(int id) => _byId[id];

  /// Resolve type from cache only, return null if missing.
  EvtTypeRec? resolveByName(String name) => _byName[name];

  /// Clear all from cache
  void clearCache() {
    _byId = {};
    _byName = {};
    Logger.root.fine("Cleared event type cache");
  }

  void remove(int id, String name) {
    _byId.remove(id);
    _byName.remove(name);
    notifyListeners();
  }
}

class EvtTypeManagerPersist extends EvtTypeManager {
  final DBService _db;

  EvtTypeManagerPersist({required DBService db, super.types}) : _db = db;

  /// Get a type id, trying in priority:
  /// 1. get type-id from cache
  /// 2. get from DB or create and persist new
  Future<int> resolveOrCreate({required String name}) async {
    final cached = resolveByName(name)?.id;
    if (cached != null) {
      return cached;
    }
    final fromDB = await _db.eventTypes.getOrCreate(name);
    add(fromDB.id, EvtTypeRec.fromIsar(fromDB));
    // state has updated
    notifyListeners();
    return fromDB.id;
  }

  /// Save new or update event-type. returns id
  Future<int> saveOrUpdate(EvtTypeRec type) async {
    final newId = await _db.eventTypes.saveOrUpdateByName(type);
    add(newId, type);
    // state has updated
    notifyListeners();
    return newId;
  }

  /// Check DB for dangling EvtType references
  Future<List<int>> danglingTypeRefs() async {
    final [refs, existing] = await Future.wait([_db.events.allReferencedTypeIds(), _db.eventTypes.allIds()]);

    final dangling = refs.difference(existing).toList();
    dangling.sort();
    return dangling;
  }

  @override
  Future<bool> remove(int id, String name) async {
    final didDelete = await _db.eventTypes.delete(id);
    super.remove(id, name);
    return didDelete;
  }

  // create new types at missing ids.
  Future<List<int>> fillDangling() async {
    final ids = await danglingTypeRefs();
    final created = <int>[];
    for (var i in ids) {
      final newId = await _db.eventTypes.putWithId(i, "_new_type_$i");
      if (newId != null) {
        created.add(newId);
      }
    }
    notifyListeners();
    return created;
  }
}
