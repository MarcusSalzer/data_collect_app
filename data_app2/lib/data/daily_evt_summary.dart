class DailyEvtSummary {
  final DateTime dateUtc;

  // --- Human readable ---
  final int eventCount;
  final Duration totalDuration;

  // --- Structural fingerprints ---
  final int sumStartEpochSec;
  final int xorMix;

  const DailyEvtSummary({
    required this.dateUtc,
    required this.eventCount,
    required this.totalDuration,
    required this.sumStartEpochSec,
    required this.xorMix,
  });

  @override
  operator ==(Object other) {
    return other is DailyEvtSummary &&
        dateUtc == other.dateUtc &&
        eventCount == other.eventCount &&
        totalDuration == other.totalDuration &&
        sumStartEpochSec == other.sumStartEpochSec &&
        xorMix == other.xorMix;
  }

  @override
  String toString() {
    return "($eventCount, $totalDuration, $sumStartEpochSec, $xorMix)";
  }

  @override
  int get hashCode => Object.hash(dateUtc, eventCount, totalDuration, sumStartEpochSec, xorMix);
}
