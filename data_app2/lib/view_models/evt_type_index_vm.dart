import 'dart:collection';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/util/stats.dart';
import 'package:flutter/material.dart';

class EvtTypeIndexVm extends ChangeNotifier {
  final DBService _db;
  final EvtTypeManagerPersist _typeManager;

  EvtTypeIndexVm(this._db, this._typeManager);

  LinkedHashMap<int, int>? _idToCount;
  LinkedHashMap<int, int>? get idToCount => _idToCount;

  int countOf(EvtTypeRec rec) => _idToCount?[rec.id] ?? 0;

  Iterable<int> danglingTypeRefs = {};

  EvtTypeRec? eventType(int id) {
    return _typeManager.typeFromId(id);
  }

  List<EvtTypeRec>? get itemsSorted {
    final freqs = _idToCount;
    if (freqs == null) {
      return null;
    }

    // Copy list of all types
    final types = [..._typeManager.allTypes];

    // Sort by descending (zeros at end)
    types.sort((a, b) {
      final af = freqs[a.id] ?? 0;
      final bf = freqs[b.id] ?? 0;
      // Higher freq first
      return bf.compareTo(af);
    });

    return types;
  }

  Future<void> load() async {
    // refresh types and categories
    final (t, c) = await _db.allTypesAndCats();
    _typeManager.reloadFromModels(t, c);
    // Check for dangling type references
    danglingTypeRefs = await _db.danglingTypeRefs();
    await refreshCounts();
    notifyListeners();
  }

  /// Count each event type
  Future<void> refreshCounts() async {
    final evts = await _db.evts.all();

    var counts = valueCounts<int>(evts.map((e) => e.typeId));

    _idToCount = LinkedHashMap.fromEntries(counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  Future<List<int>> recreateDanglingTypes() async {
    final created = await _typeManager.fillDanglingTypeRefs();
    await load(); // also reload
    return created;
  }
}
