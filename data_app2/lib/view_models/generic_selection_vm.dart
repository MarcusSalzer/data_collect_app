import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/stats.dart';
import 'package:data_app2/util/text_search.dart';
import 'package:flutter/material.dart';

typedef TextOf<T> = String Function(T);
typedef IdOf<T> = int? Function(T);

/// Allow selecting things
class GenericSelectionVm<T> extends ChangeNotifier {
  GenericSelectionVm({required List<T> Function() source, required this.idOf, required this.textOf, required this.app})
    : _source = source;

  final AppState app;
  final List<T> Function() _source;
  final IdOf<T> idOf;
  final TextOf<T> textOf;

  String _query = '';
  final Set<int> _selected = {};

  String get query => _query;
  Set<int> get selected => _selected;
  int get nSelected => _selected.length;
  bool get anySelected => _selected.isNotEmpty;

  void setQuery(String q) {
    _query = q.toLowerCase().trim();
    notifyListeners();
  }

  void toggle(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void selectAll() {
    _selected.addAll(filtered.map(idOf).removeNulls);
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  bool isSelected(int id) => _selected.contains(id);

  List<T> get filtered {
    final all = _source();
    if (_query.isEmpty) return all;

    return textSearchFilter<T>(_query, all, app.textSearchMode, textOf).toList();
  }
}
