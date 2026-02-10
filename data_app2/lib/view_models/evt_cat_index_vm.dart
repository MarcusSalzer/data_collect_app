import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/util/stats.dart';
import 'package:flutter/material.dart';

class EvtCatIndexVm extends ChangeNotifier {
  EvtCatIndexVm(this._app);
  final AppState _app;

  // State
  Map<int, int>? _idToCount;
  final List<EvtCatRec> _allItems = [];

  // public
  Map<int, int>? get idToCount => _idToCount;

  List<EvtCatRec>? get itemsSorted {
    final freqs = _idToCount;
    if (freqs == null) {
      return null;
    }

    // Sort by descending frequency (zeros at end)
    _allItems.sort((a, b) => (freqs[b.id] ?? 0).compareTo(freqs[a.id] ?? 0));

    return _allItems;
  }

  Future<void> load() async {
    _allItems.clear();
    _allItems.addAll(await _app.db.evtCats.all());
    _idToCount = await refreshCounts();
    notifyListeners();
  }

  Future<Map<int, int>> refreshCounts() async {
    // Load evtTypes from DB and count references to categories
    final evtTypes = await _app.db.evtTypes.all();

    // value-count all types with a category
    var counts = valueCounts<int>(evtTypes.map((e) => e.categoryId).removeNulls);

    // Maps ids to counts, no order needed
    return Map.fromEntries(counts.entries);
  }
}
