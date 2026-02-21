import 'dart:ui';

import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/data/evt_cat.dart';

class EvtCatCsvCodec extends CsvCodecRW<EvtCatDraft> {
  EvtCatCsvCodec({super.sep});
  @override
  get schema => CsvSchemasConst.evtCat;

  @override
  build(CsvRow r) {
    final color32 = r.optInt("color");
    if (color32 != null) {
      return EvtCatDraft(r.req("name"), Color(color32));
    } else {
      return EvtCatDraft(r.req("name"));
    }
  }

  @override
  toRow(d) {
    return CsvRow({"name": d.name, "color": d.color.toARGB32().toString()});
  }
}
