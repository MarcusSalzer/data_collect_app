import 'package:data_app2/fmt.dart';
import 'package:test/test.dart';

void main() {
  test('monthName', () {
    expect(Fmt.monthName(DateTime(2073, 1)), "January");
    expect(Fmt.monthName(DateTime(2073, 2)), "February");
  });
  test("full datetime", () {
    expect(Fmt.dtSecond(DateTime(2004, 10, 11)), "2004-10-11 00:00:00");
    expect(Fmt.dtSecond(DateTime(2004, 10, 11, 01, 13, 53)),
        "2004-10-11 01:13:53");
  });
}
