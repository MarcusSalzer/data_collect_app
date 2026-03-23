// Keep current settings in memory, for convenient access

import 'dart:ui';

import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/util/event_stats_compute.dart';
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
}

DurationSummaryList<EvtTypeRec> computeSummaryFromEvts(
  Iterable<EvtRec> evts,
  EvtTypeRec? Function(int) resolveType,
  Color Function(EvtTypeRec) resolveColor,
) {
  final tpe = timePerEvent(evts, limit: 16);

  final List<TypeDurSummaryItem> results = [];

  for (var MapEntry(key: id, value: d) in tpe) {
    final et = resolveType(id);
    if (et == null) {
      Logger.root.severe("TodaySummaryVm: Could not resolve type $id");
      continue;
    }
    results.add(TypeDurSummaryItem(et, d, resolveColor(et)));
  }

  return DurationSummaryList<EvtTypeRec>(results);
}

DurationSummaryList<EvtCatRec> groupSummaryByType(
  DurationSummaryList<EvtTypeRec> byType,
  EvtCatRec? Function(int) resolveCat,
) {
  final byCatMap = <int, Duration>{};

  // aggregate durations
  for (var e in byType.items) {
    byCatMap[e.rec.categoryId] = (byCatMap[e.rec.categoryId] ?? Duration.zero) + e.duration;
  }

  final List<CatDurSummaryItem> results = [];

  for (var MapEntry(key: id, value: d) in byCatMap.entries) {
    final cat = resolveCat(id);
    if (cat == null) {
      Logger.root.severe("TodaySummaryVm: Could not resolve cat $id");
      continue;
    }
    results.add(CatDurSummaryItem(cat, d));
  }

  // sort descending
  results.sort((a, b) => b.duration.compareTo(a.duration));

  return DurationSummaryList(results);
}
