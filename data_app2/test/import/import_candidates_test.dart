import 'dart:io';

import 'package:data_app2/csv/evt_csv_adapter.dart';
import 'package:data_app2/csv/evt_type_csv_adapter.dart';
import 'package:data_app2/import/import_candidate_collection.dart';
import 'package:test/test.dart';

import '../test_util/paths.dart';

void main() {
  late final List<File> files;

  final headerEvt = EvtCsvAdapter().header;
  final headerEvtType = EvtTypeCsvAdapter().header;

  setUpAll(() async {
    files = await Future.wait(
      ["a.csv", "b.csv", "c.csv", "d.csv"].map((x) => getTmpFile(x)),
    );
    files[0].writeAsStringSync("random,trash,columns\n0,1,2\n3,4,5\n");
    files[1].writeAsStringSync("$headerEvt\n0,1,2\n3,4,5");
    files[2].writeAsStringSync("$headerEvtType\n0,1,2\n3,4,5\n");
    files[3].writeAsStringSync("$headerEvt\n0,1,2\n3,4,5\n");
  });
  test("add candidates", () async {
    final col = ImportCandidateCollection();
    await col.addFile(files[0]);

    expect(col.evtCands.length, 0);
    expect(col.evtTypeCands.length, 0);
    expect(col.unknownCands.length, 1);
    expect(col.canImport, false);

    await col.addFile(files[1]);
    expect(col.canImport, true);
    await col.addFile(files[2]);
    await col.addFile(files[3]);

    expect(col.evtCands.length, 2);
    expect(col.evtTypeCands.length, 1);
    expect(col.unknownCands.length, 1);
    expect(col.canImport, true);
  });
}
