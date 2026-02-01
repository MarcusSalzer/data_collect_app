import 'package:data_app2/csv_2/csv_schema.dart';

/// Consts for domain models
class CsvSchemasConst {
  static const evt = CsvSchema(["type", "start_utc", "start_offset_s", "end_utc", "end_offset_s"], {"type"});
  static const evtCat = CsvSchema(["name"], {"name"});
  static const evtType = CsvSchema(["name", "category"], {"name"});
}
