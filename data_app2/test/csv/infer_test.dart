import 'package:data_app2/csv/evt_csv_adapter.dart';
import 'package:data_app2/csv/evt_type_csv_adapter.dart';
import 'package:data_app2/csv/infer_from_header.dart';
import 'package:data_app2/util/enums.dart';
import 'package:test/test.dart';

import '../test_util/paths.dart';

void main() {
  // get a temp folder for the tests
  setUpAll(() async {
    // tempDir = await getTmpDir();
  });
  test("read header only", () async {
    final file = await getTmpFile();
    await file.writeAsString("A,B,C\n1,2,3");

    final cols = await getCsvHeaderCols(file);
    expect(cols, {"A", "B", "C"});
  });
  test("infer header from cols", () {
    expect(roleFromCols(EvtCsvAdapter().cols.toSet()), ImportFileRole.events);
    expect(
      roleFromCols(EvtTypeCsvAdapter().cols.toSet()),
      ImportFileRole.eventTypes,
    );
    expect(roleFromCols({"some", "random", "trash"}), ImportFileRole.unknown);
  });
}
