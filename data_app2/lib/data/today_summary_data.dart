// Keep current settings in memory, for convenient access

import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/util/event_stats_compute.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class TodaySummaryDataByType {
  final List<MapEntry<EvtTypeRec, Duration>> tpe;
  TodaySummaryDataByType(this.tpe);

  Duration get trackedTime => tpe.fold(Duration.zero, (p, c) => p + c.value);
}

sealed class DurSummaryItem<T> {
  final T rec;
  final Duration duration;

  String get name;
  Color get color;

  DurSummaryItem(this.rec, this.duration);
}

class TypeDurSummaryItem extends DurSummaryItem<EvtTypeRec> {
  TypeDurSummaryItem(super.rec, super.duration, this.color);

  @override
  Color color;

  @override
  String get name => rec.name;
}

class CatDurSummaryItem extends DurSummaryItem<EvtCatRec> {
  CatDurSummaryItem(super.rec, super.duration);

  @override
  Color get color => rec.color;

  @override
  String get name => rec.name;
}

/// Summary item in format to display
class DurationSummaryList<T> {
  final List<DurSummaryItem<T>> items;
  DurationSummaryList(this.items);

  Duration get trackedTime => items.fold(Duration.zero, (p, c) => p + c.duration);

  bool get isEmpty => items.isEmpty;

  @override
  String toString() {
    return "DurationSummaryList($trackedTime, ${items.length} items)";
  }
}

/// For filling unknown durations in summaries
const unknownFillId = -1;

DurationSummaryList<EvtTypeRec> computeSummaryFromEvts(
  Iterable<EvtRec> evts,
  EvtTypeRec? Function(int) resolveType,
  Color Function(EvtTypeRec) resolveColor, {
  Duration? total,
}) {
  final tpe = timePerEvent(evts);

  final List<TypeDurSummaryItem> results = [];
  var sum = Duration.zero;
  // resolve type for each counted event
  for (var MapEntry(key: id, value: d) in tpe) {
    sum += d;
    final et = resolveType(id);
    if (et == null) {
      Logger.root.severe("computeSummaryFromEvts: Could not resolve type $id");
      // add a dummy record
      results.add(TypeDurSummaryItem(EvtTypeRec(-1, "[error]"), d, Colors.grey));
    } else {
      results.add(TypeDurSummaryItem(et, d, resolveColor(et)));
    }
  }
  // optionally fill rest to total duration
  if (total != null) {
    results.add(
      TypeDurSummaryItem(EvtTypeRec(unknownFillId, "unknown", unknownFillId), total - sum, Colors.transparent),
    );
  }
  return DurationSummaryList<EvtTypeRec>(results);
}

DurationSummaryList<EvtCatRec> groupSummaryByCat(
  DurationSummaryList<EvtTypeRec> byType,
  EvtCatRec? Function(int) resolveCat,
) {
  final byCatMap = <int, Duration>{};

  // aggregate durations
  for (var e in byType.items) {
    byCatMap[e.rec.categoryId] = (byCatMap[e.rec.categoryId] ?? Duration.zero) + e.duration;
  }

  final List<DurSummaryItem<EvtCatRec>> results = [];

  for (var MapEntry(key: id, value: d) in byCatMap.entries) {
    // if it is a "unknown fill" save for later
    if (id == unknownFillId) {
      continue;
    }
    final cat = resolveCat(id);
    if (cat == null) {
      throw StateError("groupSummaryByCat: Could not resolve cat $id");
    }
    results.add(CatDurSummaryItem(cat, d));
  }

  // sort descending
  results.sort((a, b) => b.duration.compareTo(a.duration));

  // after sorting add unkown-entry
  final dUnknown = byCatMap[unknownFillId];
  if (dUnknown != null) {
    results.add(CatDurSummaryItem(EvtCatRec(unknownFillId, "unknown", Colors.transparent), dUnknown));
  }

  return DurationSummaryList(results);
}
