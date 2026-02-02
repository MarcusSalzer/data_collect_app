import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/util/summary_period_aggs.dart';

/// Writes CSV with one time column, and one column per type.
class PeriodAggCsvWriter extends CsvCodecWrite<PeriodAgg> {
  final GroupFreq _f;

  // can have any cols
  final List<String> typeNames;

  PeriodAggCsvWriter(this._f, this.typeNames);

  @override
  toRow(PeriodAgg rec) {
    return CsvRow({
      _f.name: Fmt.date(rec.dt, f: _f),
      for (var (i, dur) in rec.agg.indexed) typeNames[i]: Fmt.durationHm(dur),
    });
  }

  @override
  get schema => CsvSchema([_f.name, ...typeNames], {});
}

/// Writes CSV with two columns: time and total
class PeriodAggTotCsvWriter extends CsvCodecWrite<PeriodAgg> {
  final GroupFreq _f;

  PeriodAggTotCsvWriter(this._f);
  @override
  get schema => CsvSchema([_f.name, "duration"], {});

  @override
  toRow(PeriodAgg rec) {
    return CsvRow({_f.name: Fmt.date(rec.dt, f: _f), "duration": Fmt.durationHm(rec.total())});
  }
}
