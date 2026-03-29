import 'package:data_app2/local_datetime.dart';
import 'package:test/test.dart';

void main() {
  group('constructors and factories', () {
    test('From local', () {
      final dt = DateTime.now().copyWith(microsecond: 0);
      final ldt = LocalDateTime.fromLocal(dt);

      expect(ldt.asLocal, dt);
      expect(ldt.offset, dt.timeZoneOffset);
      expect(ldt.asUtc, dt.toUtc());
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
      expect(ldt.toNaiveIso8601String(includeMs: true), '2023-05-01T15:00:00.000');
      expect(ldt.toUtcIso8601String(includeMs: true), '2023-05-01T12:00:00.000Z');
      // Only second precicion
      expect(ldt.toNaiveIso8601String(includeMs: false), '2023-05-01T15:00:00');
      expect(ldt.toUtcIso8601String(includeMs: false), '2023-05-01T12:00:00Z');
    });
  });

  test('equality', () {
    final dt = DateTime(2025, 08, 19, 12, 12, 33, 4, 34);
    final l1 = LocalDateTime.fromLocal(dt);
    final l2 = LocalDateTime.fromLocal(dt);
    expect(l1 == l2, true);
    expect(l1.hashCode == l2.hashCode, true);
  });
  test('inequality', () {
    final l1 = LocalDateTime.fromLocal(
      DateTime(2025, 08, 19, 12, 12, 33, 4, 34),
    );
    final l2 = LocalDateTime.fromLocal(
      DateTime(2025, 08, 19, 12, 13, 33, 4, 34),
    );
    expect(l1 != l2, true);
  });
  group('asLocal', () {
    test('utc flag is false', () {
      expect(LocalDateTime(0, 0).asLocal.isUtc, false);
    });
    test('no offset', () {
      expect(LocalDateTime(0, 0).asLocal, DateTime.parse("1970-01-01T00:00:00"));
    });
    test('with offset', () {
      expect(LocalDateTime(0, Duration(minutes: 5).inMilliseconds).asLocal, DateTime.parse("1970-01-01T00:05:00"));
      expect(LocalDateTime(0, -Duration(minutes: 5).inMilliseconds).asLocal, DateTime.parse("1969-12-31T23:55:00"));
    });
    test('milliseconds shift same as Dart DT at same moment', () {
      expect(
        LocalDateTime(0, 0).asLocal.millisecondsSinceEpoch,
        0 - DateTime.fromMillisecondsSinceEpoch(0).timeZoneOffset.inMilliseconds,
      );

      expect(
        LocalDateTime(10, 10).asLocal.millisecondsSinceEpoch,
        10 - DateTime.fromMillisecondsSinceEpoch(10).timeZoneOffset.inMilliseconds,
      );

      expect(
        LocalDateTime(0, 10).asLocal.millisecondsSinceEpoch,
        10 - DateTime.fromMillisecondsSinceEpoch(0).timeZoneOffset.inMilliseconds,
      );
    });
  });
  group('to string', () {
    test('utcIso', () {
      expect(LocalDateTime(0, 0).toUtcIso8601String(), '1970-01-01T00:00:00Z');
      // offset should not affect utc
      expect(LocalDateTime(0, 1000).toUtcIso8601String(), '1970-01-01T00:00:00Z');
      expect(LocalDateTime(0, -1000).toUtcIso8601String(), '1970-01-01T00:00:00Z');
    });

    test('naiveIso', () {
      expect(LocalDateTime(0, 0).toNaiveIso8601String(), '1970-01-01T00:00:00');
      // with offset
      expect(LocalDateTime(0, Duration(minutes: 5).inMilliseconds).toNaiveIso8601String(), '1970-01-01T00:05:00');
      expect(LocalDateTime(0, -Duration(minutes: 5).inMilliseconds).toNaiveIso8601String(), '1969-12-31T23:55:00');
    });
  });
}
