// Simplified parsing (only for the human-schema)

import 'package:data_app2/db_service.dart';
import 'package:data_app2/local_datetime.dart';

class EvtDraft {
  final int? id;
  final String typeName;
  final LocalDateTime? start;
  final LocalDateTime? end;

  EvtDraft({
    required this.id,
    required this.typeName,
    required this.start,
    required this.end,
  });

  /// get event draft from db
  /// throws if not in repo
  factory EvtDraft.fromIsar(Event e, String typeName) {
    return EvtDraft(
      id: e.id,
      typeName: typeName,
      start: LocalDateTime.maybeFromMillis(
        e.startUtcMillis,
        e.startLocalMillis,
      ),
      end: LocalDateTime.maybeFromMillis(
        e.endUtcMillis,
        e.endLocalMillis,
      ),
    );
  }

  Event toIsar(int typeId) {
    final evt = Event(
      typeId: typeId,
      startLocalMillis: start?.localMillis,
      startUtcMillis: start?.utcMillis,
      endLocalMillis: end?.localMillis,
      endUtcMillis: end?.utcMillis,
    );
    // add id if it has
    final currentId = id;
    if (currentId != null) evt.id = currentId;

    return evt;
  }

  @override
  String toString() {
    return "Evtdraft($id, $typeName, $start, $end)";
  }
}

abstract class SimpleCsvAdapter<T> {
  final List<String> cols;
  SimpleCsvAdapter(this.cols);
  final sep = ",";
  String toRow(T rec);
  T fromRow(String row);

  String get header {
    return cols.join(sep);
  }

  /// Parse many csv rows
  /// throws format exception on failed row
  List<T> parseRows(Iterable<String> rows) {
    final recs = <T>[];
    for (var (i, r) in rows.indexed) {
      try {
        recs.add(fromRow(r));
      } on FormatException catch (e) {
        throw CsvFormatError(row: i, msg: e.message);
      }
    }
    return recs;
  }
}

/// Handles parsing, makes Draft objects
class EvtSimpleCsvAdapter extends SimpleCsvAdapter<EvtDraft> {
  EvtSimpleCsvAdapter()
      : super([
          "id",
          "type_name",
          "start_utc",
          "start_offset_s",
          "end_utc",
          "end_offset_s",
        ]);

  @override
  String toRow(EvtDraft rec) {
    return [
      rec.id,
      rec.typeName,
      rec.start?.toUtcIso8601String(),
      rec.start?.offsetSeconds,
      rec.end?.toUtcIso8601String(),
      rec.end?.offsetSeconds,
    ].join(sep);
  }

  @override
  EvtDraft fromRow(String row) {
    final items = row.split(sep);

    // parse local datetimes (allow null)
    final startOffsetS = int.tryParse(items[3]);

    final start = startOffsetS != null
        ? LocalDateTime.fromUtcISOAndffset(
            utcIso: items[2],
            offsetMillis: startOffsetS * 1000,
          )
        : null;

    final endOffsetS = int.tryParse(items[5]);

    final end = endOffsetS != null
        ? LocalDateTime.fromUtcISOAndffset(
            utcIso: items[4],
            offsetMillis: endOffsetS * 1000,
          )
        : null;
    return EvtDraft(
      id: int.parse(items[0]),
      typeName: items[1],
      start: start,
      end: end,
    );
  }
}

class CsvFormatError implements Exception {
  final int row;

  String msg;
  CsvFormatError({required this.row, required this.msg});

  @override
  String toString() {
    return "CSV Format error: $msg (at row $row)";
  }
}
