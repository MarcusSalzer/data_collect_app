import 'package:data_app2/csv/csv_util.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/util/colors.dart';

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
      throw FormatException(
        "got ${items.length} values (expected ${cols.length})",
      );
    }
    final colorname = items[2];
    return EvtTypeRec(
      id: int.parse(items[0]),
      name: items[1],
      color: ColorKey.values.firstWhere((ck) => ck.name == colorname),
    );
  }
}
