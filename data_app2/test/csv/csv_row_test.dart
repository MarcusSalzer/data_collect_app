import 'package:data_app2/csv/csv_row.dart';
import 'package:test/test.dart';

void main() {
  // example: int, string and null
  final r = CsvRow({"id": "1", "name": "hello", "maybe": null, "age": "33"});

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

    test("optional pair: null when one missing", () {
      expect(r.optPair("name", "missingField"), isNull);
    });
    test("optional pair: ok", () {
      expect(r.optPair("name", "id"), ("hello", "1"));
    });
    test("optional pair int: null when one missing", () {
      expect(r.optPairInt("name", "missingField"), isNull);
    });
    test("optional pair int: ok", () {
      expect(r.optPairInt("age", "id"), (33, 1));
    });
  });
}
