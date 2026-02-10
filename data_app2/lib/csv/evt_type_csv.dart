import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';

class EvtTypeCsvCodec extends CsvCodecRW<EvtTypeDraft> {
  EvtTypeCsvCodec({super.sep});

  @override
  CsvSchema get schema => CsvSchemasConst.evtType;

  @override
  build(CsvRow r) {
    return EvtTypeDraft(r.req("name"), r.optInt("category") ?? EvtCatRepo.defaultId);
  }

  @override
  toRow(d) {
    return CsvRow({"name": d.name, "category": d.categoryId.toString()});
  }
}
