import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/text_search.dart';
import 'package:data_app2/view_models/event_type_index_view_model.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/util/stats.dart';
import 'package:flutter/material.dart';

/// Manages selection/filtering of event types based on name
class EventTypeSelectionVM extends ChangeNotifier {
  EventTypeSelectionVM(this.source, this._app);

  final AppState _app;
  final EventTypeIndexViewModel source;

  String _query = '';
  final Set<int> _selected = {};

  String get query => _query;
  Set<int> get selected => _selected;
  int get nSelected => selected.length;
  bool get anySelected => selected.isNotEmpty;

  void setQuery(String q) {
    _query = q.toLowerCase().trim();
    notifyListeners();
  }

  void toggle(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    // shouldnt have nulls...
    _selected.addAll(filtered.map((e) => e.id).removeNulls);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  /// Check if one item is selected
  bool isSelected(int id) => _selected.contains(id);

  /// Get a filtered subset of the items in the index viewmodel
  List<EvtTypeRec> get filtered {
    final all = source.typesSorted;
    if (_query.isEmpty) return all;
    // return all.where((t) => t.name.toLowerCase().contains(_query)).toList();
    return textSearchFilter<EvtTypeRec>(
      _query,
      all,
      _app.textSearchMode,
      (r) => r.name,
    ).toList();
  }
}
