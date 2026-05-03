import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/util/enums.dart';

/// Consts for domain models
class CsvSchemasConst {
  static const evt = CsvSchema(
    ["type", "start_utc", "start_offset_s", "end_utc", "end_offset_s", "location"],
    {"type"},
  );
  static const evtCat = CsvSchema(["name"], {"name"});
  static const location = CsvSchema(["name", "lat", "lng"], {"name", "lat", "lng"});
  static const evtType = CsvSchema(["name", "category"], {"name"});

  static const byImportRole = {
    ImportFileRole.events: evt,
    ImportFileRole.eventTypes: evtType,
    ImportFileRole.eventCats: evtCat,
    ImportFileRole.locations: location,
  };
}
