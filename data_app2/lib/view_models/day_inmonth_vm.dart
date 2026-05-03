import 'dart:collection';

import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/today_summary_data.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/time_range_queries.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class DayInmonthVm extends ChangeNotifier {
  // synchronous: for starting with already loaded events for a month
  final UnmodifiableListView<EvtRec>? Function() evtsForMonth;

  /// For when stepping to ane new month
  final Future<void> Function(DateTime) stepToMonth;

  final EvtTypeManager typeManager;

  // needed prefs
  final int dayStartsH;
  final double colorSpread;
  DayInmonthVm(
    this.dt,
    this.summaryMode,
    this.colorSpread,
    this.dayStartsH,
    this.typeManager, {
    required this.evtsForMonth,
    required this.stepToMonth,
  });
  // --- state ---

  DateTime dt;
  List<EvtRec>? _dayEvts;
  List<MapEntry<int, Duration>> tpe = [];
  SummaryMode summaryMode;
  RangeSummaryInclusionMode rangeMode = RangeSummaryInclusionMode.fullyInside;
  DurationSummaryList<EvtTypeRec>? _summaryByType;

  /// Computed from type-summary, but remembered
  DurationSummaryList<EvtCatRec>? _summaryByCat;

  UnmodifiableListView<EvtRec>? get dayEvts => _dayEvts?.unmodifiable;

  /// Unified getter the UI can consume
  DurationSummaryList<dynamic>? get activeSummary {
    switch (summaryMode) {
      case SummaryMode.type:
        return _summaryByType;
      case SummaryMode.category:
        // compute if needed
        _summaryByCat ??= _computeSummaryByCat();
        return _summaryByCat;
    }
  }

  String get summaryLabel {
    final p1 = (summaryMode == SummaryMode.type) ? "Events" : "Categories";
    return "$p1 (${rangeMode.description} day)";
  }

  /// step to another day (and step month if needed)

  Future<void> stepDay(int step) async {
    final next = dt.add(Duration(days: step));
    final nextMonth = next.startOfMonth;

    if (nextMonth != dt.startOfMonth) {
      await stepToMonth(nextMonth);
    }

    dt = next;
    refresh();
  }

  void setSummaryMode(SummaryMode mode) {
    summaryMode = mode;
    notifyListeners();
  }

  /// set the range inclusion mode and recompute summary
  void setRangeMode(RangeSummaryInclusionMode mode) {
    rangeMode = mode;
    refresh();
  }

  void refresh() {
    // create a query to apply on stored local timestamps.
    final q = LocalTimeRangeQuery(
      ref: dt,
      dayOffset: Duration(hours: dayStartsH),
      unit: GroupFreq.day,
      // uses endsIn in two cases:
      overlapMode: (rangeMode == RangeSummaryInclusionMode.fullyInside)
          ? OverlapMode.fullyInside
          : OverlapMode.endInside,
    );

    final monthEvts = evtsForMonth();
    if (monthEvts == null) {
      return;
    }
    final dayEvts = monthEvts.where((e) => q.accepts(e.start, e.end)).toList();
    _dayEvts = dayEvts;
    _summaryByType = computeSummaryFromEvts(
      dayEvts,
      typeManager.typeFromId,
      (EvtTypeRec r) => typeManager.colorFor(r, colorSpread),
      // only fill in rest if desired
      total: (rangeMode == RangeSummaryInclusionMode.endsInPlusFill) ? Duration(hours: 24) : null,
    );

    _summaryByCat = null; // lazy load this later if needed

    notifyListeners();
  }

  /// Group the typeSummary and return that
  DurationSummaryList<EvtCatRec>? _computeSummaryByCat() {
    final byType = _summaryByType;
    if (byType == null) return null;
    try {
      return groupSummaryByCat(byType, typeManager.catFromId);
    } on StateError catch (e) {
      Logger.root.severe("$runtimeType: $e");
      return null;
    }
  }

  Future<void> load() async {
    await Future.delayed(Duration(seconds: 1));
    refresh();
  }
}
