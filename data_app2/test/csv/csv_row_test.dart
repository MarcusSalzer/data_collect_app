import 'package:data_app2/csv/csv_row.dart';
import 'package:test/test.dart';

void main() {
  // example: int, string and null
  final r = CsvRow({"id": "1", "name": "hello", "maybe": null});

  group("require", () {
    test('can get string', () {
      expect(r.req("name"), "hello");
    });
    test('can get int', () {
      expect(r.reqInt("id"), 1);
    });
    test('throws when missing', () {
      expect(
        () => r.req("missingField"),
        throwsA(predicate((e) => e is FormatException && e.message.contains("Missing column"))),
      );
    });
    test('throws on parse error', () {
      expect(
        () => r.reqInt("name"),
        throwsA(predicate((e) => e is FormatException && e.message.contains("Invalid radix-10 number"))),
      );
    });
  });
  group("optional", () {
    test('can get string', () {
      expect(r.opt("name"), "hello");
    });
    test('can get int', () {
      expect(r.optInt("id"), 1);
    });
    test('null when missing', () {
      expect(r.opt("missingField"), null);
      expect(r.optInt("missingField"), null);
    });
    test('throws if exists but cannot parse', () {
      expect(
        () => r.reqInt("name"),
        throwsA(predicate((e) => e is FormatException && e.message.contains("Invalid radix-10 number"))),
      );
    });
  });
}
