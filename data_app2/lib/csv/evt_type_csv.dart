import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';

class EvtTypeCsvCodec extends CsvCodecRW<EvtTypeDraft> {
  final String? Function(int) catNameFromId;
  final int? Function(String) catIdFromName;
  EvtTypeCsvCodec({super.sep, required this.catNameFromId, required this.catIdFromName});

  /// Get reslve-functions from a typemanager
  EvtTypeCsvCodec.fromTypeManager(EvtTypeManager tm)
    : this(catNameFromId: (i) => tm.catFromId(i)?.name, catIdFromName: (i) => tm.catFromName(i)?.id);

  @override
  CsvSchema get schema => CsvSchemasConst.evtType;

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
