import 'package:data_app2/data/evt_type_rec.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/summary_period_aggs.dart';

/// Data class for the computed summary
class SummaryWithPeriodAggs {
  final List<PeriodAgg> aggs;
  final List<EvtTypeRec> typeRecs;
  final GroupFreq f;

  final int nEvt;

  int get nTypes => typeRecs.length;
  DateTime get start => aggs.first.dt;
  DateTime get end => aggs.last.dt;

  SummaryWithPeriodAggs(this.aggs, this.typeRecs, this.f, this.nEvt);
}
