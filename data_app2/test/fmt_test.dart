import 'package:data_app2/fmt.dart';
import 'package:test/test.dart';

void main() {
  test('monthName', () {
    expect("January", Fmt.monthName(DateTime(2073, 1)));
    expect("February", Fmt.monthName(DateTime(2073, 2)));
  });
}
