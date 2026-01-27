// Keep current settings in memory, for convenient access

import 'package:data_app2/data/evt_type_rec.dart';
import 'package:data_app2/util/colors.dart';

class TodaySummaryDataByType {
  final List<MapEntry<EvtTypeRec, Duration>> tpe;
  TodaySummaryDataByType(this.tpe);

  Duration get trackedTime => tpe.fold(Duration.zero, (p, c) => p + c.value);
}

class SummaryItem {
  final String name;
  final ColorKey color;
  final Duration duration;

  SummaryItem(this.name, this.color, this.duration);
}

/// Summary item in format to display
class SummaryDataList {
  final List<SummaryItem> items;
  SummaryDataList(this.items);

  Duration get trackedTime => items.fold(Duration.zero, (p, c) => p + c.duration);
}
