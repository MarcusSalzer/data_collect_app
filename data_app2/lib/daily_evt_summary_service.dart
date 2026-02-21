import 'package:data_app2/data/daily_evt_summary.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';

/// Comapct string hash
int fnv1a32(String s) {
  const int fnvPrime = 0x01000193;
  int hash = 0x811C9DC5;

  for (final c in s.codeUnits) {
    hash ^= c;
    hash = (hash * fnvPrime) & 0xffffffff;
  }
  return hash;
}

int _rotl32(int x, int r) {
  return ((x << r) | (x >>> (32 - r))) & 0xffffffff;
}

class DailyEvtSummaryService {
  // can get type by .resolveById()
  final EvtTypeManager typeManager;

  DailyEvtSummaryService(this.typeManager);

  Future<List<DailyEvtSummary>> buildAll(DBService db) async {
    await Future.delayed(Duration(milliseconds: 300));
    // refresh type cache
    final (types, cats) = await db.allTypesAndCats();
    typeManager.reloadFromModels(types, cats);

    // starting point
    final startAt = (await db.evts.oldest())?.start?.asUtc.startOfDay;
    if (startAt == null) return [];
    final stopAt = DateTime.now().toUtc().add(Duration(days: 1)).startOfDay;

    final allEvts = await db.evts.all();

    // Group events by UTC day
    final byDay = <DateTime, List<EvtRec>>{};

    for (final e in allEvts) {
      final s = e.start?.asUtc;
      if (s == null) continue;

      (byDay[s.startOfDay] ??= []).add(e);
    }

    final result = <DailyEvtSummary>[];

    // Include empty days too
    for (final day in GroupFreq.day.genRange(startAt, stopAt)) {
      result.add(buildDay(day, byDay[day] ?? []));
    }

    return result;
  }

  DailyEvtSummary buildDay(DateTime date, Iterable<EvtRec> events) {
    int count = 0;
    int totalDurSec = 0;
    int sumStart = 0;
    int xorMix = 0;

    for (final e in events) {
      final s = e.start;
      // Skip if no start time
      if (s == null) continue;

      count++;

      final startSec = s.utcMillis ~/ 1000;
      sumStart += startSec;

      final d = e.duration;
      if (d != null) {
        totalDurSec += d.inSeconds;
      }

      final typName = typeManager.typeFromId(e.typeId)?.name ?? "_missing_type_";
      final typeHash = fnv1a32(typName);

      xorMix ^= _rotl32(typeHash, startSec % 31);
    }

    return DailyEvtSummary(
      dateUtc: date,
      eventCount: count,
      totalDuration: Duration(seconds: totalDurSec),
      sumStartEpochSec: sumStart,
      xorMix: xorMix,
    );
  }
}

enum DailyDriftKind {
  missingInDb,
  missingInFile,
  perfectMatch,

  eventCountMismatch,
  durationMismatch,
  startTimeMismatch,
  typeFingerprintMismatch,

  likelyTimezoneShift,
  unknownMismatch,
}

class DailySummaryDiff {
  final DateTime dateUtc;
  final DailyDriftKind kind;
  final String message;

  const DailySummaryDiff({required this.dateUtc, required this.kind, required this.message});
}

/// Vibe-coded heuristics and stuff.
class DailySummaryComparator {
  DailySummaryDiff _compareDay(DailyEvtSummary db, DailyEvtSummary file) {
    if (db == file) {
      return DailySummaryDiff(dateUtc: db.dateUtc, kind: DailyDriftKind.perfectMatch, message: "Match");
    }

    // --- Heuristic classification ---

    // Event count mismatch = strongest signal
    if (db.eventCount != file.eventCount) {
      return DailySummaryDiff(
        dateUtc: db.dateUtc,
        kind: DailyDriftKind.eventCountMismatch,
        message: "db: ${db.eventCount}, file: ${file.eventCount})",
      );
    }

    // Duration mismatch but same count → likely edits
    if (db.totalDuration != file.totalDuration) {
      return DailySummaryDiff(
        dateUtc: db.dateUtc,
        kind: DailyDriftKind.durationMismatch,
        message: "Total duration differs (${db.totalDuration} vs ${file.totalDuration})",
      );
    }

    // Detect possible timezone shift
    final startDiff = (db.sumStartEpochSec - file.sumStartEpochSec).abs();

    final perEventShift = db.eventCount == 0 ? 0 : startDiff ~/ db.eventCount;

    if (perEventShift % 1800 == 0) {
      return DailySummaryDiff(
        dateUtc: db.dateUtc,
        kind: DailyDriftKind.likelyTimezoneShift,
        message: "Start times shifted ~${Duration(seconds: perEventShift)} per event",
      );
    }

    // Start mismatch (not clean shift)
    if (db.sumStartEpochSec != file.sumStartEpochSec) {
      return DailySummaryDiff(
        dateUtc: db.dateUtc,
        kind: DailyDriftKind.startTimeMismatch,
        message: "Start time fingerprint differs",
      );
    }

    // Type fingerprint mismatch
    if (db.xorMix != file.xorMix) {
      return DailySummaryDiff(
        dateUtc: db.dateUtc,
        kind: DailyDriftKind.typeFingerprintMismatch,
        message: "Type fingerprint differs",
      );
    }

    return DailySummaryDiff(
      dateUtc: db.dateUtc,
      kind: DailyDriftKind.unknownMismatch,
      message: "Unknown structural difference",
    );
  }

  List<DailySummaryDiff> compare(List<DailyEvtSummary> db, List<DailyEvtSummary> file) {
    final dbMap = {for (final d in db) d.dateUtc: d};
    final fileMap = {for (final d in file) d.dateUtc: d};

    final allDays = {...dbMap.keys, ...fileMap.keys}.toList()..sort();

    final result = <DailySummaryDiff>[];

    for (final day in allDays) {
      final a = dbMap[day];
      final b = fileMap[day];

      if (a == null) {
        result.add(
          DailySummaryDiff(dateUtc: day, kind: DailyDriftKind.missingInDb, message: "Day exists in file but not DB"),
        );
        continue;
      }

      if (b == null) {
        result.add(
          DailySummaryDiff(dateUtc: day, kind: DailyDriftKind.missingInFile, message: "Day exists in DB but not file"),
        );
        continue;
      }

      result.add(_compareDay(a, b));
    }

    return result;
  }
}
