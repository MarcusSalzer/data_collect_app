import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/util/colors.dart';

class EvtTypeCsvCodec extends CsvCodecRW<EvtTypeDraft> {
  EvtTypeCsvCodec({super.sep});

  @override
  CsvSchema get schema => CsvSchemasConst.evtType;

  @override
  build(CsvRow r) {
    final cname = r.opt("color");

    return EvtTypeDraft(r.req("name"), colorKeysByName[cname] ?? ColorKey.base, r.optInt("category"));
  }

  @override
  toRow(d) {
    return CsvRow({"name": d.name, "category": d.categoryId?.toString()});
  }
}
