// Tricky things....

import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';

/// How does the DB look at time?
/// Can be applied to LOCAL or UTC timelines
sealed class DbTimeRange {
  final int startMs;
  final int endMs;
  final OverlapMode overlap;
  const DbTimeRange(this.startMs, this.endMs, this.overlap);

  @override
  String toString() {
    return "($startMs, $endMs, ${overlap.name})";
  }
}

class UtcDbTimeRange extends DbTimeRange {
  UtcDbTimeRange(super.startMs, super.endMs, super.overlap);

  @override
  bool operator ==(Object other) {
    return other is UtcDbTimeRange && other.startMs == startMs && other.endMs == endMs && other.overlap == overlap;
  }

  @override
  int get hashCode => Object.hash(startMs, endMs, overlap);
}

class LocalDbTimeRange extends DbTimeRange {
  LocalDbTimeRange(super.startMs, super.endMs, super.overlap);

  @override
  bool operator ==(Object other) {
    return other is LocalDbTimeRange && other.startMs == startMs && other.endMs == endMs && other.overlap == overlap;
  }

  @override
  int get hashCode => Object.hash(startMs, endMs, overlap);
}

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
  final DateTime ref; // must be isUtc = true

  const UtcTimeRangeQuery({required this.ref, required super.unit, required super.overlapMode});

  DateTime get _start => ref.startOfPeriodUtc(unit);
  DateTime get _end => switch (unit) {
    GroupFreq.day => _start.add(const Duration(days: 1)),
    GroupFreq.week => _start.add(const Duration(days: 7)),
    GroupFreq.month => DateTime.utc(_start.year, _start.month + 1),
  };
  @override
  UtcDbTimeRange toDbRange() {
    // Do not proceed if not utc time
    if (!ref.isUtc) {
      throw AssertionError("Expects UTC time");
    }

    return UtcDbTimeRange(_start.millisecondsSinceEpoch, _end.millisecondsSinceEpoch, overlapMode);
  }

  @override
  toString() => "($_start, $_end) ${overlapMode.name}";

  @override
  bool accepts(LocalDateTime evtStart, LocalDateTime evtEnd) {
    return switch (overlapMode) {
      OverlapMode.fullyInside => evtStart.asUtc.isAfter(_start) && evtEnd.asUtc.isBefore(_end),
      OverlapMode.endInside => evtEnd.asUtc.isAfter(_start) && evtEnd.asUtc.isBefore(_end),
      OverlapMode.overlapping => evtEnd.asUtc.isAfter(_start) && evtStart.asUtc.isBefore(_end),
    };
  }
}

class LocalTimeRangeQuery extends TimeRangeQuery {
  final DateTime ref; // must NOT be utc (ignores TZ)
  final Duration dayOffset; // when the day starts in relation to local 00:00.

  DateTime get _start => ref.startOfPeriod(unit).add(dayOffset);
  DateTime get _end => switch (unit) {
    GroupFreq.day => DateUtils.addDaysToDate(_start, 1).add(dayOffset),
    GroupFreq.week => DateUtils.addDaysToDate(_start, 7).add(dayOffset),
    GroupFreq.month => DateUtils.addMonthsToMonthDate(ref, 1).add(dayOffset),
  };

  int get _startMillis => _start.millisecondsSinceEpoch + _start.timeZoneOffset.inMilliseconds;
  int get _endMillis => _end.millisecondsSinceEpoch + _end.timeZoneOffset.inMilliseconds;

  const LocalTimeRangeQuery({
    required this.ref,
    required this.dayOffset,
    required super.unit,
    super.overlapMode = OverlapMode.fullyInside,
  });
  @override
  toString() => "($_start, $_end) ${overlapMode.name}";

  @override
  LocalDbTimeRange toDbRange() {
    return LocalDbTimeRange(_startMillis, _endMillis, overlapMode);
  }

  /// High level filtering: Is the event considered inside this range?
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
      OverlapMode.endInside => evtEnd.localMillis > _startMillis && evtEnd.localMillis <= _endMillis,
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
