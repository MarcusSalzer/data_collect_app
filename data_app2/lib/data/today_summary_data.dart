// Keep current settings in memory, for convenient access

import 'package:data_app2/user_events.dart';

class TodaySummaryData {
  final List<MapEntry<EvtTypeRec, Duration>> tpe;
  Duration get trackedTime => tpe.fold(Duration.zero, (p, c) => p + c.value);
  TodaySummaryData(this.tpe);
}
