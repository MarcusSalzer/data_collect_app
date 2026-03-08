import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/csv/evt_type_csv.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';
import 'package:test/test.dart';

void main() {
  test("EvtType drafts", () {
    final typMan = EvtTypeManager();
    typMan.reloadFromModels([], [
      EvtCatRec(EvtCatRepo.defaultId, "default"),
      EvtCatRec(EvtCatRepo.defaultId + 1, "a"),
    ]);
    final codec = EvtTypeCsvCodec.fromTypeManager(typMan);
    final lines = ["name,category", "hello,a", "world,default"];
    final recs = codec.decode(parseRows(lines));
    final written = codec.encodeWithHeader(recs).toList();
    expect(written, lines);
  });
}
