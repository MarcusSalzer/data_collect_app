import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/util/colors.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Handle caching/storing and resolves types from id and name etc.
class EvtTypeManager extends ChangeNotifier {
  // Store both maps for fast lookup
  Map<String, EvtTypeRec> _byName = {};
  Map<int, EvtTypeRec> _byId = {};

  // To look up which how many in each category
  Map<int, int> _catSizes = {};
  // To look up which "position" each type has in its category.
  Map<int, int> _posInCat = {};

  /// optionally fill with types
  EvtTypeManager({Iterable<EvtTypeRec>? types}) {
    if (types != null) {
      _fill(types);
    }
  }

  List<EvtTypeRec> get all => _byId.values.toList();

  /// Fill the cache and recompute things
  void _fill(Iterable<EvtTypeRec> evtTypes) {
    _byName = {};
    _byId = {};
    // Category membership
    _catSizes = {};
    _posInCat = {};
    for (var rec in evtTypes) {
      _byName[rec.name] = rec;
      _byId[rec.id] = rec;
    }
  }

  /// Reset cache and fill
  void reloadFromModels(Iterable<EvtTypeRec> evtTypes) {
    _fill(evtTypes);
    notifyListeners();
  }

  /// add a single type
  void add(EvtTypeRec rec) {
    _byName[rec.name] = rec;
    _byId[rec.id] = rec;
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
    _byName.remove(name);
    _byId.remove(id);
    notifyListeners();
  }
}

class EvtTypeManagerPersist extends EvtTypeManager {
  final DBService _db;

  EvtTypeManagerPersist({required DBService db, super.types}) : _db = db;

  /// Get a type id, trying in priority:
  /// 1. get type-id from cache
  /// 2. get from DB or create and persist new
  Future<EvtTypeRec> resolveOrCreate({required String name}) async {
    final cached = resolveByName(name);
    if (cached != null) {
      return cached;
    }
    final fromDB = await _db.eventTypes.getOrCreate(name);
    add(fromDB);
    // state has updated
    notifyListeners();
    return fromDB;
  }

  /// Delete both from DB and cache
  @override
  Future<bool> remove(int id, String name) async {
    final didDelete = await _db.eventTypes.forceDelete(id);
    super.remove(id, name);
    return didDelete;
  }

  // create new types at missing ids.
  Future<List<int>> fillDanglingTypeRefs() async {
    final created = await _db.fillDanglingTypeRefs();
    notifyListeners();
    return created;
  }
}
