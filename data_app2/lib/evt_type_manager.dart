import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/util/colors.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Handle caching/storing and resolves from id and name etc.
/// Keeps both [EvtTypeRec] and [EvtCatRec]
class EvtTypeManager extends ChangeNotifier {
  // Store both maps for fast lookup
  Map<String, EvtTypeRec> _typesByName = {};
  Map<int, EvtTypeRec> _typesById = {};
  // also store categories
  Map<int, EvtCatRec> _catsById = {};

  // To look up which how many in each category
  Map<int, int> _catSizes = {};
  // To look up which "position" each type has in its category.
  Map<int, int> _posInCat = {};

  List<EvtTypeRec> get allTypes => _typesById.values.toList();

  /// Fill the cache and recompute things
  void _fill(Iterable<EvtTypeRec> evtTypes) {
    _typesByName = {};
    _typesById = {};
    // Category membership
    _catSizes = {};
    _posInCat = {};

    // make list and sort by name, to get "stable" order of positions in categories
    final typeList = evtTypes.toList();
    typeList.sort((a, b) => a.name.compareTo(b.name));

    for (var rec in evtTypes) {
      _typesByName[rec.name] = rec;
      _typesById[rec.id] = rec;

      // Category stats
      final catId = rec.categoryId;
      final pos = _catSizes[catId] ?? 0;
      _catSizes[catId] = pos + 1;
      _posInCat[rec.id] = pos;
    }
  }

  /// Reset cache and fill
  void reloadFromModels(Iterable<EvtTypeRec> evtTypes, Iterable<EvtCatRec> cats) {
    _catsById = Map.fromEntries(cats.map((e) => MapEntry(e.id, e)));
    _fill(evtTypes);
    notifyListeners();
  }

  /// add a single type
  void add(EvtTypeRec rec) {
    _typesByName[rec.name] = rec;
    _typesById[rec.id] = rec;
    notifyListeners();
  }

  Color colorFor(EvtTypeRec? evtType, double spread) {
    if (evtType == null) {
      return ColorEngine.defaultColor;
    }
    final cat = _catsById[evtType.categoryId];
    if (cat == null) {
      return ColorEngine.defaultColor;
    }
    return ColorEngine.spread(cat.color, _posInCat[evtType.id] ?? 0, _catSizes[cat.id] ?? 1, spread);
  }

  Color colorForId(int id, double spread) => colorFor(resolveById(id), spread);

  /// Resolve type from cache only, return null if missing.
  EvtTypeRec? resolveById(int id) => _typesById[id];

  /// Resolve type from cache only, return null if missing.
  EvtTypeRec? resolveByName(String name) => _typesByName[name];

  /// Clear all from cache
  void clearCache() {
    _typesById = {};
    _typesByName = {};
    Logger.root.fine("Cleared event type cache");
  }

  void remove(int id, String name) {
    _typesByName.remove(name);
    _typesById.remove(id);
    notifyListeners();
  }
}

class EvtTypeManagerPersist extends EvtTypeManager {
  final DBService _db;

  EvtTypeManagerPersist(DBService db) : _db = db;

  /// Get a type id, trying in priority:
  /// 1. get type-id from cache
  /// 2. get from DB or create and persist new
  Future<EvtTypeRec> resolveOrCreate({required String name}) async {
    final cached = resolveByName(name);
    if (cached != null) {
      return cached;
    }
    final fromDB = await _db.evtTypes.getOrCreate(name);
    add(fromDB);
    // state has updated
    notifyListeners();
    return fromDB;
  }

  /// Delete both from DB and cache
  @override
  Future<bool> remove(int id, String name) async {
    final didDelete = await _db.evtTypes.forceDelete(id);
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
