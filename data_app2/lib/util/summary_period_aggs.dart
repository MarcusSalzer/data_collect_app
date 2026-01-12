import 'package:data_app2/user_events.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';

/// Store aggregates for one period
class PeriodAgg {
  // period start
  final DateTime dt;
  // count for each type
  final List<Duration> agg;
  PeriodAgg(this.dt, int nTypes) : agg = List.filled(nTypes, Duration.zero);

  /// Create from a prefilled map
  PeriodAgg.filled(this.dt, this.agg);

  void add(int key, Duration d) {
    agg[key] += d;
  }

  Duration total() {
    return agg.reduce((p, c) => p + c);
  }
}

List<PeriodAgg> computeAggs(
  Iterable<EvtRec> evts,
  List<EvtTypeRec> typeRecs,
  GroupFreq f,
) {
  if (evts.isEmpty) {
    return List.empty();
  }
  final nTypes = typeRecs.length;
  final aggs = <DateTime, PeriodAgg>{};
  var first = DateTime.now();
  var last = DateTime.now();

  final Map<int?, int> typeIdToIdx = Map.fromEntries(
    Iterable.generate(nTypes).map((i) => MapEntry(typeRecs[i].id, i)),
  );

  for (var e in evts) {
    // assume belongs to end time (local)
    final period = e.end?.asLocal.startOfPeriod(f);
    if (period == null) continue;
    final d = e.duration;
    if (d == null) continue;

    // keep track of range
    if (period.isBefore(first)) {
      first = period;
    } else if (period.isAfter(last)) {
      last = period;
    }

    final aggIdx = typeIdToIdx[e.typeId];
    if (aggIdx != null) {
      // count this event
      final a = aggs[period];
      if (a != null) {
        a.add(aggIdx, d);
      } else {
        aggs[period] = PeriodAgg(period, nTypes)..add(aggIdx, d);
      }
    }
  }

  // fill in gaps with empty, uses ascending range
  return f
      .genRange(first, last)
      .map((dt) => (aggs[dt] ?? PeriodAgg(dt, nTypes)))
      .toList();
}
