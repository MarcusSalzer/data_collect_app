import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';

/// Handle caching/storing and resolves types from id and name etc.
class EvtTypeRepository extends ChangeNotifier {
  // Store both maps for fast lookup
  Map<String, EvtTypeRec> _byName = {};
  Map<int, EvtTypeRec> _byId = {};

  /// optionally fill with types
  ///
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
  fillFromIsar(Iterable<EventType> evtTypes) {
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
  add(int id, EvtTypeRec rec) {
    _byName[rec.name] = rec;
    _byId[id] = rec;
    notifyListeners();
  }

  EvtTypeRec? resolveById(int id) => _byId[id];
  EvtTypeRec? resolveByName(String name) => _byName[name];
}

class EvtTypeRepositoryPersist extends EvtTypeRepository {
  final DBService _db;

  EvtTypeRepositoryPersist({required DBService db, super.types}) : _db = db;

  /// Get a type id, trying in priority:
  /// 1. get type-id from cache
  /// 2. get type-id from DB
  /// 3. Create and save a new type, return its persisted id
  Future<int> resolveOrCreate(AppState app, {required String name}) async {
    final cached = resolveByName(name)?.id;
    if (cached != null) {
      return cached;
    }
    final fromDB = await _db.getEventType(name: name);
    if (fromDB != null) {
      add(fromDB.id, EvtTypeRec.fromIsar(fromDB));
      return fromDB.id;
    }

    // create item
    final etRec = EvtTypeRec(name: name);
    // save to db
    final newTypeId = await _db.newEventType(name);
    // save to cache
    _byName[name] = etRec;
    _byId[newTypeId] = etRec;
    // state has updated
    notifyListeners();
    // just return id
    return newTypeId;
  }

  /// Save new or update event-type. returns id
  Future<int> updateType(EvtTypeRec type) async {
    final newId = await _db.putEventType(type);
    type.id = newId;
    _byId[newId] = type;
    _byName[type.name] = type;
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
    // print("refs  $refs");
    // print("exist $existing");
    // print("dangl $dangling");
    return dangling;
  }
}
