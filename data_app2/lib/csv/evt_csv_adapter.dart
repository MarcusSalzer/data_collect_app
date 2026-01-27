import 'package:data_app2/csv/csv_util.dart';
import 'package:data_app2/data/evt_draft.dart';
import 'package:data_app2/data/evt_rec.dart';
import 'package:data_app2/local_datetime.dart';

/// Parses "human" schema, makes [EvtDraft] objects
class EvtCsvAdapter extends CsvAdapter<EvtDraft> {
  const EvtCsvAdapter();
  @override
  List<String> get cols => ["id", "type_name", "start_utc", "start_offset_s", "end_utc", "end_offset_s"];

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
        ? LocalDateTime.fromUtcISOAndffset(utcIso: items[2], offsetMillis: startOffsetS * 1000)
        : null;

    final endOffsetS = int.tryParse(items[5]);

    final end = endOffsetS != null
        ? LocalDateTime.fromUtcISOAndffset(utcIso: items[4], offsetMillis: endOffsetS * 1000)
        : null;
    return EvtDraft(id: int.parse(items[0]), typeName: items[1], start: start, end: end);
  }
}

/// Parses "raw" schema, makes [EvtRec] objects
class EvtCsvAdapterRaw extends CsvAdapter<EvtRec> {
  const EvtCsvAdapterRaw();
  @override
  List<String> get cols => ["id", "type_id", "start_utc_ms", "start_local_ms", "end_utc_ms", "end_local_ms"];
  @override
  String toRow(EvtRec evt) {
    return [
      evt.id,
      evt.typeId,
      evt.start?.utcMillis,
      evt.start?.localMillis,
      evt.end?.utcMillis,
      evt.end?.localMillis,
    ].join(sep);
  }

  @override
  EvtRec fromRow(String row) {
    final items = row.split(sep);
    if (items.length != cols.length) {
      throw FormatException("got ${items.length} values (expected ${cols.length})");
    }
    return EvtRec(
      id: int.parse(items[0]),
      typeId: int.parse(items[1]),
      // parse nullable timestamps
      start: LocalDateTime.maybeFromMillis(int.tryParse(items[2]), int.tryParse(items[3])),
      end: LocalDateTime.maybeFromMillis(int.tryParse(items[4]), int.tryParse(items[5])),
    );
  }
}
