import 'dart:collection';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_cat_rec.dart';
import 'package:data_app2/util/stats.dart';
import 'package:flutter/material.dart';

class EventCatIndexViewModel extends ChangeNotifier {
  final AppState _app;
  // State
  LinkedHashMap<int, int>? _idToCount;
  final List<EvtCatRec> allItems = [];

  List<EvtCatRec> get itemsSorted {
    final freqs = _idToCount;
    if (freqs == null) {
      return [];
    }

    // Sort by descending (zeros at end)
    allItems.sort((a, b) {
      final af = freqs[a.id] ?? 0;
      final bf = freqs[b.id] ?? 0;
      // Higher freq first
      return bf.compareTo(af);
    });

    return allItems;
  }

  void _onRepoChanged() async {
    await load();
    notifyListeners();
  }

  EventCatIndexViewModel(this._app) {
    // propagate updates from eventType repo
    _app.evtTypeManager.addListener(_onRepoChanged);
  }

  Future<void> load() async {
    allItems.clear();
    allItems.addAll(await _app.db.categories.all());
    await refreshCounts();
    notifyListeners();
  }

  /// Count each event type
  Future<void> refreshCounts() async {
    final evtTypes = await _app.db.eventTypes.all();

    // value-count all types with a category
    var counts = valueCounts<int>(evtTypes.map((e) => e.categoryId).removeNulls);

    _idToCount = LinkedHashMap.fromEntries(counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  @override
  void dispose() {
    _app.evtTypeManager.removeListener(_onRepoChanged);
    super.dispose();
  }
}
