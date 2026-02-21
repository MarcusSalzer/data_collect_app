// Tricky things....

import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';

/// How does the DB look at time?
/// Can be applied to LOCAL or UTC timelines
class DbTimeRange {
  final int startMs;
  final int endMs;
  final OverlapMode overlap;
  const DbTimeRange(this.startMs, this.endMs, this.overlap);

  @override
  String toString() {
    return "($startMs, $endMs, ${overlap.name})";
  }

  @override
  bool operator ==(Object other) {
    return other is DbTimeRange && other.startMs == startMs && other.endMs == endMs && other.overlap == overlap;
  }

  @override
  int get hashCode => Object.hash(startMs, endMs, overlap);
}

enum OverlapMode { fullyInside, overlapping }

sealed class TimeRangeQuery {
  final GroupFreq unit;
  final OverlapMode overlapMode;
  const TimeRangeQuery({required this.unit, required this.overlapMode});

  DbTimeRange toDbRange();

  /// high level filtering.
  /// The query range includes start and excludes end.
  bool accepts(LocalDateTime evtStart, LocalDateTime evtEnd);
}

class UtcTimeRangeQuery extends TimeRangeQuery {
  final DateTime referenceUtc; // must be isUtc = true

  const UtcTimeRangeQuery({required this.referenceUtc, required super.unit, required super.overlapMode});

  DateTime get _start => referenceUtc.startOfPeriodUtc(unit);
  DateTime get _end => switch (unit) {
    GroupFreq.day => _start.add(const Duration(days: 1)),
    GroupFreq.week => _start.add(const Duration(days: 7)),
    GroupFreq.month => DateTime.utc(_start.year, _start.month + 1),
  };
  @override
  DbTimeRange toDbRange() {
    // Do not proceed if not utc time
    if (!referenceUtc.isUtc) {
      throw AssertionError("Expects UTC time");
    }

    return DbTimeRange(_start.millisecondsSinceEpoch, _end.millisecondsSinceEpoch, overlapMode);
  }

  @override
  toString() => "($_start, $_end) ${overlapMode.name}";

  @override
  bool accepts(LocalDateTime evtStart, LocalDateTime evtEnd) {
    return switch (overlapMode) {
      OverlapMode.fullyInside => evtStart.asUtc.isAfter(_start) && evtEnd.asUtc.isBefore(_end),
      OverlapMode.overlapping => evtEnd.asUtc.isAfter(_start) && evtStart.asUtc.isBefore(_end),
    };
  }
}

class LocalTimeRangeQuery extends TimeRangeQuery {
  final DateTime ref; // must NOT be utc (ignores TZ)
  final Duration dayOffset;

  DateTime get _start => ref.startOfPeriod(unit).add(dayOffset);
  DateTime get _end => switch (unit) {
    GroupFreq.day => ref.startOfPeriod(unit).add(const Duration(days: 1)),
    GroupFreq.week => ref.startOfPeriod(unit).add(const Duration(days: 7)),
    GroupFreq.month => ref.endOfMonthUtc,
  }.add(dayOffset);

  /// Note: computed through "fake-utc"
  int get _startMillis => _start.millisecondsSinceEpoch;
  int get _endMillis => _end.millisecondsSinceEpoch;

  const LocalTimeRangeQuery({
    required this.ref,
    required this.dayOffset,
    required super.unit,
    required super.overlapMode,
  });
  @override
  toString() => "($_start, $_end) ${overlapMode.name}";

  @override
  DbTimeRange toDbRange() {
    return DbTimeRange(_startMillis, _endMillis, overlapMode);
  }

  @override
  bool accepts(LocalDateTime? evtStart, LocalDateTime? evtEnd) {
    if (evtStart == null) {
      return evtEnd != null && overlapMode == OverlapMode.overlapping && evtEnd.localMillis > _startMillis;
    }
    if (evtEnd == null) {
      return overlapMode == OverlapMode.overlapping && evtStart.localMillis <= _endMillis;
    }
    return switch (overlapMode) {
      OverlapMode.fullyInside => evtStart.localMillis > _startMillis && evtEnd.localMillis <= _endMillis,
      OverlapMode.overlapping => evtEnd.localMillis > _startMillis && evtStart.localMillis <= _endMillis,
    };
  }
}

/// CROP THING..
Duration computeOverlap(int eventStart, int eventEnd, int rangeStart, int rangeEnd) {
  final effectiveStart = eventStart > rangeStart ? eventStart : rangeStart;

  final effectiveEnd = eventEnd < rangeEnd ? eventEnd : rangeEnd;

  if (effectiveEnd <= effectiveStart) {
    return Duration.zero;
  }

  return Duration(milliseconds: effectiveEnd - effectiveStart);
}
