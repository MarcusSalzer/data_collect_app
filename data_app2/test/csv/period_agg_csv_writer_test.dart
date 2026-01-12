import 'package:data_app2/csv/period_agg_csv_writer.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/util/summary_period_aggs.dart';
import 'package:test/test.dart';

final typeNames = ["A", "B"];
List<PeriodAgg> getAggs(List<DateTime> times) {
  return [
    PeriodAgg.filled(times[0], [Duration(hours: 1), Duration(hours: 2)]),
    PeriodAgg.filled(times[1], [Duration(hours: 1), Duration(minutes: 2)]),
    PeriodAgg.filled(times[2], [
      Duration(hours: 3, minutes: 59),
      Duration(hours: 2),
    ]),
  ];
}

void main() {
  group('Totals writer', () {
    test("header", () {
      for (var f in GroupFreq.values) {
        expect(PeriodAggTotCsvWriter(f).header, "${f.name},duration");
      }
    });
    test("writes ok (day)", () {
      final writer = PeriodAggTotCsvWriter(GroupFreq.day);
      final dates = GroupFreq.day
          .genRange(DateTime(2020), DateTime(2020, 1, 3))
          .toList();
      final lines = writer.encodeRowsWithHeader(getAggs(dates)).toList();
      expect(lines, [
        writer.header,
        "2020-01-01,03:00",
        "2020-01-02,01:02",
        "2020-01-03,05:59",
      ]);
    });
    test("writes ok (month)", () {
      final writer = PeriodAggTotCsvWriter(GroupFreq.month);
      final dates = GroupFreq.month
          .genRange(DateTime(2020, 11), DateTime(2021, 1))
          .toList();
      final lines = writer.encodeRowsWithHeader(getAggs(dates)).toList();
      expect(lines, [
        writer.header,
        "2020-11,03:00",
        "2020-12,01:02",
        "2021-01,05:59",
      ]);
    });
  });

  group("Separate writer", () {
    test("header", () {
      for (var f in GroupFreq.values) {
        expect(PeriodAggCsvWriter(f, typeNames).header, "${f.name},A,B");
      }
    });
  });
}
