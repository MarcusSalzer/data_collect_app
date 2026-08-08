import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/util/enums.dart';

/// Consts for domain models
class CsvSchemasConst {
  // event
  static const evtHuman = CsvSchema(
    ["type", "start_utc", "start_offset_s", "end_utc", "end_offset_s", "location"],
    {"type"},
  );
  static const evtRaw = CsvSchema(
    ["id", "type_id", "start_utc", "start_offset_s", "end_utc", "end_offset_s", "location_id"],
    {"id", "type_id"},
  );

  // category
  static const evtCatHuman = CsvSchema(["name"], {"name"});
  static const evtCatRaw = CsvSchema(["id", "name"], {"id", "name"});

  // location
  static const locationHuman = CsvSchema(["name", "lat", "lng"], {"name", "lat", "lng"});
  static const locationRaw = CsvSchema(["id", "name", "lat", "lng"], {"id", "name", "lat", "lng"});

  // event type
  static const evtTypeHuman = CsvSchema(["name", "category"], {"name"});
  static const evtTypeRaw = CsvSchema(["id", "name", "category_id"], {"id", "name"});

  static const byImportRoleHuman = {
    ImportFileRole.events: evtHuman,
    ImportFileRole.eventTypes: evtTypeHuman,
    ImportFileRole.eventCats: evtCatHuman,
    ImportFileRole.locations: locationHuman,
  };
  static const byImportRoleRaw = {
    ImportFileRole.events: evtRaw,
    ImportFileRole.eventTypes: evtTypeRaw,
    ImportFileRole.eventCats: evtCatRaw,
    ImportFileRole.locations: locationRaw,
  };
}
