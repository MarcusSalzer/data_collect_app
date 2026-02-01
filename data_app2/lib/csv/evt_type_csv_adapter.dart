import 'package:data_app2/csv/csv_util_old.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/util/colors.dart';

@Deprecated("use map pipeline instead")
class EvtTypeCsvAdapter extends CsvAdapter<EvtTypeRec> {
  const EvtTypeCsvAdapter();
  @override
  List<String> get cols => ["id", "name", "color"];

  @override
  String toRow(EvtTypeRec rec) {
    return [
      rec.id,
      rec.name,
      rec.color.name,
      // rec.categoryId,
    ].join(sep);
  }

  @override
  EvtTypeRec fromRow(String row) {
    final items = row.split(sep);
    if (items.length != cols.length) {
      throw FormatException("got ${items.length} values (expected ${cols.length})");
    }
    final colorname = items[2];
    final catId = 0;
    return EvtTypeRec(int.parse(items[0]), items[1], ColorKey.values.firstWhere((ck) => ck.name == colorname), catId);
  }
}
