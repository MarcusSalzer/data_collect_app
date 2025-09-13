import 'package:data_app2/db_service.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';

/// Handle caching/storing and resolves types from id and name etc.
class EvtTypeRepository extends ChangeNotifier {
  // Store both maps for fast lookup
  Map<String, EvtTypeRec> _byName = {};
  Map<int, EvtTypeRec> _byId = {};

  /// optionally fill with types
  ///_evtFreqs
  /// Note: only provided types with id included
  EvtTypeRepository({Iterable<EvtTypeRec>? types}) {
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
  void fillFromIsar(Iterable<EventType> evtTypes) {
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

  EvtTypeRec? resolveById(int id) => _byId[id];
  EvtTypeRec? resolveByName(String name) => _byName[name];

  /// Clear all from cache
  void clearCache() {
    _byId = {};
    _byName = {};
  }
}

class EvtTypeRepositoryPersist extends EvtTypeRepository {
  final DBService _db;

  EvtTypeRepositoryPersist({required DBService db, super.types}) : _db = db;

  /// Get a type id, trying in priority:
  /// 1. get type-id from cache
  /// 2. get from DB or create and persist new
  Future<int> resolveOrCreate({required String name}) async {
    final cached = resolveByName(name)?.id;
    if (cached != null) {
      return cached;
    }
    final fromDB = await _db.getOrCreateEventType(name);
    add(fromDB.id, EvtTypeRec.fromIsar(fromDB));
    // state has updated
    notifyListeners();
    return fromDB.id;
  }

  /// Save new or update event-type. returns id
  Future<int> saveOrUpdate(EvtTypeRec type) async {
    final newId = await _db.saveOrUpdateEventTypeByName(type);
    add(newId, type);
    // state has updated
    notifyListeners();
    return newId;
  }

  /// Check DB for dangling EvtType references
  Future<List<int>> danglingTypeRefs() async {
    final [refs, existing] =
        await Future.wait([_db.allReferencedTypeIds(), _db.allTypeIds()]);

    final dangling = refs.difference(existing).toList();
    dangling.sort();
    return dangling;
  }
}
