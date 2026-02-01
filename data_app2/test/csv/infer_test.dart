import 'package:data_app2/csv/infer_from_header.dart';
import 'package:data_app2/csv_2/builtin_schemas.dart';
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
    expect(roleFromCols(CsvSchemasConst.evt.writeCols.toSet()), ImportFileRole.events);
    expect(roleFromCols(CsvSchemasConst.evtType.writeCols.toSet()), ImportFileRole.eventTypes);
    expect(roleFromCols(CsvSchemasConst.evtCat.writeCols.toSet()), ImportFileRole.eventCats);
    expect(roleFromCols({"some", "random", "trash"}), ImportFileRole.unknown);
  });
}
