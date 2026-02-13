import 'dart:collection';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/util/stats.dart';
import 'package:flutter/material.dart';

class EventTypeIndexViewModel extends ChangeNotifier {
  final AppState _app;

  LinkedHashMap<int, int>? _idToCount;
  LinkedHashMap<int, int>? get idToCount => _idToCount;

  int countOf(EvtTypeRec rec) => _idToCount?[rec.id] ?? 0;
  Color colorOf(EvtTypeRec rec) => _app.colorFor(rec);

  Iterable<int> danglingTypeRefs = {};

  EvtTypeRec? eventType(int id) {
    return _app.evtTypeManager.resolveById(id);
  }

  List<EvtTypeRec>? get itemsSorted {
    final freqs = _idToCount;
    if (freqs == null) {
      return null;
    }

    // Copy list of all types
    final types = [..._app.evtTypeManager.allTypes];

    // Sort by descending (zeros at end)
    types.sort((a, b) {
      final af = freqs[a.id] ?? 0;
      final bf = freqs[b.id] ?? 0;
      // Higher freq first
      return bf.compareTo(af);
    });

    return types;
  }

  EventTypeIndexViewModel(this._app);

  Future<void> load() async {
    // refresh types and categories
    final (t, c) = await _app.db.allTypesAndCats();
    _app.evtTypeManager.reloadFromModels(t, c);
    // Check for dangling type references
    danglingTypeRefs = await _app.db.danglingTypeRefs();
    await refreshCounts();
    notifyListeners();
  }

  /// Count each event type
  Future<void> refreshCounts() async {
    final evts = await _app.db.evts.all();

    var counts = valueCounts<int>(evts.map((e) => e.typeId));

    _idToCount = LinkedHashMap.fromEntries(counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  Future<List<int>> recreateDanglingTypes() async {
    final created = await _app.evtTypeManager.fillDanglingTypeRefs();
    await load(); // also reload
    return created;
  }
}
