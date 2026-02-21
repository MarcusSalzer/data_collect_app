import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/local_datetime.dart';

class EvtCsvCodec extends CsvCodecRW<EvtDraft> {
  EvtCsvCodec({super.sep, required this.typMan});
  EvtTypeManager typMan; // Needed to resolve types

  @override
  get schema => CsvSchemasConst.evt;

  /// Parse data for LocalDateTime
  /// p=(utc string and offset in seconds)
  LocalDateTime? _getLdt((String, String)? p) {
    return (p == null) ? null : LocalDateTime.fromUtcISOAndOffset(utcIso: p.$1, offsetMillis: int.parse(p.$2) * 1000);
  }

  @override
  build(CsvRow r) {
    final typName = r.req("type");
    final typ = typMan.typeFromName(typName);
    if (typ == null) {
      throw FormatException("Unknown type: '$typName'");
    }
    return EvtDraft(
      typ.id,
      start: _getLdt(r.optPair("start_utc", "start_offset_s")),
      end: _getLdt(r.optPair("end_utc", "end_offset_s")),
    );
  }

  @override
  toRow(d) {
    final typ = typMan.typeFromId(d.typeId);
    if (typ == null) {
      throw FormatException("Unknown type: '${d.typeId}'");
    }
    return CsvRow({
      "type": typ.name,
      "start_utc": d.start?.toUtcIso8601String(),
      "start_offset_s": d.start?.offsetSeconds.toString(),
      "end_utc": d.end?.toUtcIso8601String(),
      "end_offset_s": d.end?.offsetSeconds.toString(),
    });
  }
}
