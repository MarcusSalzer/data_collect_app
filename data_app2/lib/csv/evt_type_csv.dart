import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';

class EvtTypeCsvCodecHuman extends CsvCodecRW<EvtTypeDraft> {
  final String? Function(int) catNameFromId;
  final int? Function(String) catIdFromName;
  EvtTypeCsvCodecHuman({super.sep, required this.catNameFromId, required this.catIdFromName});

  /// Get resolve-functions from a typemanager
  EvtTypeCsvCodecHuman.fromTypeManager(EvtTypeManager tm)
    : this(catNameFromId: (i) => tm.catFromId(i)?.name, catIdFromName: (i) => tm.catFromName(i)?.id);

  @override
  CsvSchema get schema => CsvSchemasConst.evtTypeHuman;

  @override
  build(CsvRow r) {
    final catName = r.opt("category");
    final catId = (catName != null) ? catIdFromName(catName) : EvtCatRepo.defaultId;
    if (catId == null) throw FormatException("Unknown category: $catName");

    return EvtTypeDraft(r.req("name"), catId);
  }

  @override
  toRow(d) {
    final catName = catNameFromId(d.categoryId);
    if (catName == null) throw FormatException("Unknown category: ${d.categoryId}");

    return CsvRow({"name": d.name, "category": catName});
  }
}

class EvtTypeCsvCodecRaw extends CsvCodecRW<EvtTypeRec> {
  EvtTypeCsvCodecRaw({super.sep});

  @override
  CsvSchema get schema => CsvSchemasConst.evtTypeRaw;

  @override
  build(CsvRow r) {
    return EvtTypeRec(r.reqInt("id"), r.req("name"), r.optInt("category_id") ?? EvtCatRepo.defaultId);
  }

  @override
  toRow(d) {
    return CsvRow({"id": d.id.toString(), "name": d.name, "category_id": d.categoryId.toString()});
  }
}
