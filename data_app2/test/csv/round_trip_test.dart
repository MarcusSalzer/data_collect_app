import 'package:data_app2/csv_2/evt_type_csv.dart';
import 'package:test/test.dart';

void main() {
  test("EvtType drafts", () {
    final codec = EvtTypeCsvCodec();
    final lines = ["name,category", "hello,", "world,3"];
    final recs = codec.decode(codec.parseRows(lines));
    final written = codec.encode(recs).toList();
    expect(written, lines);
  });
}
