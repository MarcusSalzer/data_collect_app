class LocalDateTime {
  final int utcMillis; // absolute point in time
  final int localMillis; // = utcMillis + offsetMillis

  const LocalDateTime(this.utcMillis, this.localMillis);

  int get offsetMillis => localMillis - utcMillis;
  int get offsetSeconds => offsetMillis ~/ 1000;

  Duration get offset => Duration(milliseconds: offsetMillis);

  DateTime get asUtc => DateTime.fromMillisecondsSinceEpoch(utcMillis, isUtc: true);

  /// Note: The DateTime object will have [isUtc] true.
  DateTime get asUtcWithLocalValue => DateTime.fromMillisecondsSinceEpoch(localMillis, isUtc: true);

  factory LocalDateTime.now() {
    final dt = DateTime.now();
    return LocalDateTime.fromDateTimeLocalTZ(dt);
  }

  LocalDateTime.fromDateTimeLocalTZ(DateTime dt)
    : utcMillis = dt.millisecondsSinceEpoch,
      localMillis = dt.millisecondsSinceEpoch + dt.timeZoneOffset.inMilliseconds;

  factory LocalDateTime.fromUtcISOAndOffset({required String utcIso, required int offsetMillis}) {
    if (!utcIso.endsWith("Z")) {
      throw FormatException("Expected UTC ISO string with 'Z' suffix", utcIso);
    }

    final utcMillis = DateTime.parse(utcIso).millisecondsSinceEpoch;

    return LocalDateTime(utcMillis, utcMillis + offsetMillis);
  }

  /// High level construction from Dart built-in classes
  factory LocalDateTime.fromUtcAndOffset(DateTime utc, Duration offset) {
    if (!utc.isUtc) {
      throw AssertionError("Expected UTC datetime");
    }

    final utcMillis = utc.millisecondsSinceEpoch;

    return LocalDateTime(utcMillis, utcMillis + offset.inMilliseconds);
  }

  LocalDateTime copyWith({int? utcMillis, int? localMillis}) {
    return LocalDateTime(utcMillis ?? this.utcMillis, localMillis ?? this.localMillis);
  }

  @override
  String toString() {
    return "UTC: $asUtc | offset: ${offsetMillis / 3_600_000} h";
  }

  String toUtcIso8601String({bool includeMs = false}) {
    final s = asUtc.toIso8601String();
    if (includeMs) {
      return s;
    } else {
      return s.replaceFirst(RegExp(r".\d{3}Z$"), "Z");
    }
  }

  /// Formats an ISO-8601 string, without any timezone suffix.
  String toNaiveIso8601String({bool includeMs = false}) {
    final dt = asUtcWithLocalValue.copyWith(millisecond: includeMs ? null : 0, microsecond: 0);
    final s = dt.toIso8601String();

    if (includeMs) {
      return s.replaceFirst("Z", "");
    } else {
      return s.replaceFirst(RegExp(r".\d{3}Z$"), "");
    }
  }

  @override
  bool operator ==(Object other) {
    return other is LocalDateTime && other.utcMillis == utcMillis && other.localMillis == localMillis;
  }

  @override
  int get hashCode => Object.hash(utcMillis, localMillis);

  /// Make a localdatetime or null if some timestamp is missing
  static LocalDateTime? maybeFromMillis(int? utcMillis, int? localMillis) {
    if (utcMillis == null || localMillis == null) {
      return null;
    }
    return LocalDateTime(utcMillis, localMillis);
  }

  /// Create a copy, shifted in both local and UTC
  LocalDateTime add(Duration duration) {
    final shiftMillis = duration.inMilliseconds;
    return LocalDateTime(utcMillis + shiftMillis, localMillis + shiftMillis);
  }

  /// Create a copy, shifted in both local and UTC
  LocalDateTime subtract(Duration duration) => add(-duration);
}
