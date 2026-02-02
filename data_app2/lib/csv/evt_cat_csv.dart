import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/data/evt_cat.dart';

// TODO Color
class EvtCatCsvCodec extends CsvCodecRW<EvtCatDraft> {
  EvtCatCsvCodec({super.sep});
  @override
  get schema => CsvSchemasConst.evtCat;

  @override
  build(CsvRow r) {
    return EvtCatDraft(r.req("name"));
  }

  @override
  toRow(d) {
    return CsvRow({"name": d.name});
  }
}
