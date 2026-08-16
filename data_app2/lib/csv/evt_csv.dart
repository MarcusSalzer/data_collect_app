import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/location_manager.dart';

/// Converts events to/from human-readable CSV. Needs managers to resolve type/location from name.
class EvtCsvCodecHuman extends CsvCodecRW<EvtDraft> {
  EvtCsvCodecHuman(this.typMan, this.locMan, {super.sep});
  EvtTypeManager typMan; // Needed to resolve types
  LocationManager locMan; // Needed to resolve locations

  @override
  get schema => CsvSchemasConst.evtHuman;

  @override
  build(CsvRow r) {
    // get type (required)
    final typName = r.req("type");
    final typ = typMan.typeFromName(typName);
    if (typ == null) {
      throw FormatException("Unknown type: '$typName'");
    }
    // get location (optional)
    final locName = r.opt("location");
    final loc = locName != null ? locMan.fromName(locName) : null;

    return EvtDraft(
      typ.id,
      start: r.optLocalDt("start_utc", "start_offset_s"),
      end: r.optLocalDt("end_utc", "end_offset_s"),
      locationId: loc?.id,
    );
  }

  @override
  toRow(d) {
    final typ = typMan.typeFromId(d.typeId);
    if (typ == null) {
      throw StateError("Unknown typeId: '${d.typeId}', i know of : ${typMan.allTypes.map((t) => t.id).join(', ')}");
    }
    final loc = locMan.fromId(d.locationId);
    if (d.locationId != null && loc == null) {
      throw StateError(
        "Unknown locationId: '${d.locationId}', i know of : ${locMan.all.map((t) => t.id).join(', ')}",
      );
    }
    return CsvRow({
      "type": typ.name,
      "start_utc": d.start?.toUtcIso8601String(),
      "start_offset_s": d.start?.offsetSeconds.toString(),
      "end_utc": d.end?.toUtcIso8601String(),
      "end_offset_s": d.end?.offsetSeconds.toString(),
      "location": loc?.name,
    });
  }
}

/// Converts events to/from raw CSV. Important to have all files in sync!
class EvtCsvCodecRaw extends CsvCodecRW<EvtRec> {
  const EvtCsvCodecRaw({super.sep});

  @override
  get schema => CsvSchemasConst.evtRaw;

  @override
  build(CsvRow r) => EvtRec(
    r.reqInt("id"),
    r.reqInt("type_id"),
    start: r.optLocalDt("start_utc", "start_offset_s"),
    end: r.optLocalDt("end_utc", "end_offset_s"),
    locationId: r.optInt("location_id"),
  );

  @override
  toRow(d) => CsvRow({
    "id": d.id.toString(),
    "type_id": d.typeId.toString(),
    "start_utc": d.start?.toUtcIso8601String(),
    "start_offset_s": d.start?.offsetSeconds.toString(),
    "end_utc": d.end?.toUtcIso8601String(),
    "end_offset_s": d.end?.offsetSeconds.toString(),
    "location_id": d.locationId?.toString(),
  });
}
