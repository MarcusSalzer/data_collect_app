import 'package:data_app2/csv/csv_util.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/util/summary_period_aggs.dart';

/// Writes CSV with one time column, and one column per type.
class PeriodAggCsvWriter with CsvSchema, CsvWriter<PeriodAgg> {
  final GroupFreq _f;

  // can have any cols
  final List<String> _cols;

  PeriodAggCsvWriter(this._f, List<String> types) : _cols = [_f.name, ...types];

  @override
  List<String> get cols => _cols;

  @override
  String toRow(PeriodAgg rec) {
    return [
      Fmt.date(rec.dt, f: _f),
      ...rec.agg.map((d) => Fmt.durationHm(d)),
    ].join(sep);
  }
}

/// Writes CSV with two columns: time and total
class PeriodAggTotCsvWriter with CsvSchema, CsvWriter<PeriodAgg> {
  final GroupFreq _f;

  PeriodAggTotCsvWriter(this._f);
  @override
  List<String> get cols => [_f.name, "duration"];

  @override
  String toRow(PeriodAgg rec) {
    return [Fmt.date(rec.dt, f: _f), Fmt.durationHm(rec.total())].join(sep);
  }
}
