// Keep current settings in memory, for convenient access

import 'dart:ui';

import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';

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
