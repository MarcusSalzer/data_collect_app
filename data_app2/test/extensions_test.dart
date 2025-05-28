import 'package:data_app2/extensions.dart';
import 'package:test/test.dart';

void main() {
  test('startOfDay', () {
    final s = DateTime(2037, 7, 9, 13, 52, 23).startOfDay;

    expect(s, DateTime(2037, 7, 9));
  });
  test('first weekday of month', () {
    expect(DateTime(2025, 5).monthFirstWeekday, 1);
    expect(DateTime(2025, 2).monthFirstWeekday, 6);
  });
}
