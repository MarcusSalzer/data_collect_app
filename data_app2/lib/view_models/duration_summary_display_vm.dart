import 'dart:collection';

import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/today_summary_data.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';

/// View model for loading and displaying summaries of event durations
abstract class DurationSummaryDisplayVm extends ChangeNotifier {
  final Duration dayStart;
  final DBService db;
  final EvtTypeManager typeManager;
  final double colorSpread;

  DurationSummaryDisplayVm(this.dayStart, this.db, this.typeManager, this.colorSpread, this._summaryMode) {
    typeManager.addListener(_onTypesChanged);
  }

  @override
  void dispose() {
    typeManager.removeListener(_onTypesChanged);
    super.dispose();
  }

  List<EvtRec>? _evts;
  DurationSummaryList<EvtTypeRec>? _summaryByType;

  /// Computed from type-summary, but remembered
  DurationSummaryList<EvtCatRec>? _summaryByCat;

  // allow choosing which summary to show
  SummaryMode _summaryMode;
  SummaryMode get summaryMode => _summaryMode;

  UnmodifiableListView<EvtRec>? get eventList => _evts?.unmodifiable;

  void setSummaryMode(SummaryMode value) {
    if (_summaryMode == value) return;
    _summaryMode = value;
    notifyListeners();
  }

  void toggleSummaryLevel() {
    _summaryMode = _summaryMode == SummaryMode.type ? SummaryMode.category : SummaryMode.type;
    notifyListeners();
  }

  /// Unified getter the UI can consume
  DurationSummaryList<dynamic>? get activeSummary {
    switch (_summaryMode) {
      case SummaryMode.type:
        return _summaryByType;
      case SummaryMode.category:
        // compute if needed
        _summaryByCat ??= _computeSummaryByCat();
        return _summaryByCat;
    }
  }

  /// Group the typeSummary and return that
  DurationSummaryList<EvtCatRec>? _computeSummaryByCat() {
    final byType = _summaryByType;
    if (byType == null) return null;

    return groupSummaryByType(byType, typeManager.catFromId);
  }

  /// Recompute the (byType) summary and store it.
  void refreshSummary(Iterable<EvtRec> evts) {
    _summaryByType = computeSummaryFromEvts(
      evts,
      typeManager.typeFromId,
      (EvtTypeRec r) => typeManager.colorFor(r, colorSpread),
    );
    _summaryByCat = null; // lazy load this later if needed
  }

  /// Subclass implements a query to load
  LocalTimeRangeQuery get rangeQuery;

  Future<void> load() async {
    final evts = (await db.evts.filteredLocalTime(rangeQuery.toDbRange())).toList();

    // Compute summary from events, or wait for types
    if (typeManager.isReady) {
      refreshSummary(evts);
      notifyListeners();
    }

    // remember events
    _evts = evts;
  }

  void _onTypesChanged() {
    final evts = _evts;
    if (evts != null && evts.isNotEmpty && typeManager.isReady) {
      refreshSummary(evts);
    }
    notifyListeners();
  }
}
