import 'package:data_app2/local_datetime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('From local timezone', () {
    final dt = DateTime.now().copyWith(microsecond: 0);
    final localOffset = dt.timeZoneOffset;
    final ldt = LocalDateTime.fromDateTimeLocalTZ(dt);

    expect(ldt.toNaiveIso8601String(includeMs: true), dt.toIso8601String());
    expect(
        ldt.toUtcIso8601String(includeMs: true), dt.toUtc().toIso8601String());
    expect(ldt.offset, localOffset);
  });

  test('From arbitrary local millis with offset', () {
    // Pretend UTC = 12:00, Local = 15:00 (+3h)
    final utc = DateTime.utc(2023, 5, 1, 12, 0, 0);
    final offset = const Duration(hours: 3);
    final ldt = LocalDateTime(
      utc.millisecondsSinceEpoch,
      utc.millisecondsSinceEpoch + offset.inMilliseconds,
    );

    expect(ldt.offset, offset);
    // Full milisecond precision (Dart default)
    expect(
        ldt.toNaiveIso8601String(includeMs: true), '2023-05-01T15:00:00.000');
    expect(ldt.toUtcIso8601String(includeMs: true), '2023-05-01T12:00:00.000Z');
    // Only second precicion
    expect(ldt.toNaiveIso8601String(includeMs: false), '2023-05-01T15:00:00');
    expect(ldt.toUtcIso8601String(includeMs: false), '2023-05-01T12:00:00Z');
  });

  test('equality', () {
    final dt = DateTime(2025, 08, 19, 12, 12, 33, 4, 34);
    final l1 = LocalDateTime.fromDateTimeLocalTZ(dt);
    final l2 = LocalDateTime.fromDateTimeLocalTZ(dt);
    expect(l1 == l2, true);
    expect(l1.hashCode == l2.hashCode, true);
  });
  test('inequality', () {
    final l1 = LocalDateTime.fromDateTimeLocalTZ(
      DateTime(2025, 08, 19, 12, 12, 33, 4, 34),
    );
    final l2 = LocalDateTime.fromDateTimeLocalTZ(
      DateTime(2025, 08, 19, 12, 13, 33, 4, 34),
    );
    expect(l1 != l2, true);
  });

  test('more_tostrings', () {
    final ldt = LocalDateTime(0, 0);
    expect(ldt.offset, Duration.zero);
    expect(ldt.toUtcIso8601String(), '1970-01-01T00:00:00Z');
    expect(ldt.toNaiveIso8601String(), '1970-01-01T00:00:00');
  });
}
