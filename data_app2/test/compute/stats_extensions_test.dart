import 'package:data_app2/stats.dart';
import 'package:test/test.dart';

void main() {
  test('min int', () {
    expect(-99, [1, 2, -99, 2, 2, -99].min);
  });
  test('max int', () {
    expect(2, [1, 2, -99, 2, 2, -99].max);
  });
}
