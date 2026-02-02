import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/util/enums.dart';

/// Consts for domain models
class CsvSchemasConst {
  static const evt = CsvSchema(["type", "start_utc", "start_offset_s", "end_utc", "end_offset_s"], {"type"});
  static const evtCat = CsvSchema(["name"], {"name"});
  static const evtType = CsvSchema(["name", "category"], {"name"});

  static const byImportRole = {
    ImportFileRole.events: evt,
    ImportFileRole.eventTypes: evtType,
    ImportFileRole.eventCats: evtCat,
  };
}
