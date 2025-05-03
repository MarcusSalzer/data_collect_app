import 'package:data_app2/io.dart';
import 'package:test/test.dart';

void main() {
  test('parseCSV handles empty list', () {
    final lines = <String>[];
    final res = parseCSV(lines, EvtRec.fromRow);
    expect(res, Iterable.empty());
  });
  test('parseCSV handles three cols', () {
    final dt = DateTime(2023, 12, 24, 03, 55, 01); // YMDhms
    final lines = <String>[
      "hej, $dt, ${dt.add(Duration(minutes: 63))}",
      "hejdå , ${dt.add(Duration(minutes: 30)).toIso8601String()} , ${dt.add(Duration(minutes: 33)).toIso8601String()}",
    ];
    final res = parseCSV(lines, EvtRec.fromRow);
    expect(res, [
      EvtRec(null, "hej", dt, dt.add(Duration(minutes: 63))),
      EvtRec(null, "hejdå", dt.add(Duration(minutes: 30)),
          dt.add(Duration(minutes: 33))),
    ]);
  });
  test('EvtRec rejects two cols', () {
    final dt = DateTime(2023, 12, 24, 03, 55, 01); // YMDhms
    final lines = <String>[
      "hej, ${dt.add(Duration(minutes: 63))}",
    ];
    expect(() => parseCSV(lines, EvtRec.fromRow), throwsFormatException);
  });
  test('EvtRec rejects five cols', () {
    final lines = <String>[
      "hej,,,,",
    ];
    expect(() => parseCSV(lines, EvtRec.fromRow), throwsFormatException);
  });
}
