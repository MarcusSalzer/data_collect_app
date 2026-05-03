import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/csv/evt_csv.dart';
import 'package:data_app2/csv/evt_type_csv.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/location_manager.dart';
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
    final drafts = codec.decode(parseRows(lines));
    final written = codec.encodeWithHeader(drafts).toList();
    expect(written, lines);
  });

  test("Event drafts", () {
    // for resolving things
    final typMan = EvtTypeManager();
    final locMan = LocationManager();

    typMan.upsertType(EvtTypeRec(13, "hello"));
    typMan.upsertType(EvtTypeRec(14, "goodbye"));
    locMan.upsert(LocationRec(99, name: "world", lat: -1.5, lng: 2.0));

    final drafts = [
      EvtDraft(13, start: null, end: null, locationId: null),
      EvtDraft(14, start: null, end: null, locationId: 99),
    ];

    final codec = EvtCsvCodec(typMan, locMan);
    final written = codec.encodeWithHeader(drafts).toList();
    expect(written.length, 3); // Header + 2 records
    expect(written[1], "hello,,,,,");
    expect(written[2], "goodbye,,,,,world");
    final read = codec.decode(parseRows(written)).toList();

    expect(read, drafts);
  });
}
