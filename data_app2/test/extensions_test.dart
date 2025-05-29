import 'package:data_app2/extensions.dart';
import 'package:test/test.dart';

void main() {
  test('startOfDay', () {
    final s = DateTime(2037, 7, 9, 13, 52, 23).startOfDay;

    expect(s, DateTime(2037, 7, 9));
  });
  test('startOfWeek monday', () {
    expect(DateTime(2025, 7, 7).startOfweek, DateTime(2025, 7, 7));
    expect(DateTime(2025, 4, 28).startOfweek, DateTime(2025, 4, 28));
  });
  test('startOfWeek', () {
    expect(DateTime(2025, 6, 5).startOfweek, DateTime(2025, 6, 2));
  });
  test('startOfWeek accross month', () {
    expect(DateTime(2025, 5, 3).startOfweek, DateTime(2025, 4, 28));
    expect(DateTime(2025, 7, 1).startOfweek, DateTime(2025, 6, 30));
    expect(DateTime(2025, 7, 6).startOfweek, DateTime(2025, 6, 30));
  });
  test('first weekday of month', () {
    expect(DateTime(2025, 2).monthFirstWeekday, 6);
    expect(DateTime(2025, 3).monthFirstWeekday, 6);
    expect(DateTime(2025, 4).monthFirstWeekday, 2);
    expect(DateTime(2025, 5).monthFirstWeekday, 4);
  });
}
