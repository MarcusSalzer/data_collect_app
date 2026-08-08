import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/raw_data_import_manager.dart';
import 'package:data_app2/util/enums.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../../test_util/dummy_app.dart';

/// Save some stuff
/// - types: 3
/// - cats:  2
/// - random trash: 1
void makeDummyFilesRaw(Directory folder) {
  // types
  File(
    p.join(folder.path, "event_types.csv"),
  ).writeAsStringSync(["id,name,category", "1,tA,c1", "3,tB,", "4,tC,c2"].join("\n"));
  // cats
  File(
    p.join(folder.path, "event_categories.csv"),
  ).writeAsStringSync(["id,name", "2,c1", "3,c2"].join("\n"));
  // trash
  File(
    p.join(folder.path, "trash.wtf"),
  ).writeAsStringSync(["name", "c1", "c2"].join("\n"));
}

void main() {
  late final AppState app;

  setUpAll(() async {
    app = await getDummyApp();
  });

  test('empty', () async {
    final folder = await app.storeSubdir("empty_folder");
    final im = RawDataImportManager(app.db);

    await im.scan(folder);
    expect(im.candidates.length, 0);
  });

  test('file scan', () async {
    final folder = await app.storeSubdir("stuff");

    final im = RawDataImportManager(app.db);

    // write data
    makeDummyFilesRaw(folder);

    await im.scan(folder);
    expect(im.candidates.length, 2);
  });
  test('pre parse', () async {
    final folder = await app.storeSubdir("stuff");

    final im = RawDataImportManager(app.db);

    // write data
    makeDummyFilesRaw(folder);

    await im.scan(folder);
    await im.preParse();

    for (var c in im.candidates) {
      if (c.role == ImportFileRole.eventTypes) {
        expect(c.fields, containsAll(CsvSchemasConst.evtTypeRaw.requiredCols));
      } else if (c.role == ImportFileRole.eventCats) {
        expect(c.fields, containsAll(CsvSchemasConst.evtCatRaw.requiredCols));
      }
    }
  });

  test('happy path', () async {
    await app.db.clear();
    final folder = await app.storeSubdir("happy");
    final im = RawDataImportManager(app.db);

    // write data
    makeDummyFilesRaw(folder);

    await im.scan(folder);
    expect(im.canImport, false, reason: "needs to preparse before we know");
    await im.preParse();
    expect(im.canImport, true);

    final importRes = await im.import();
    expect(im.timings.keys, ["scan", "preParse", "import"], reason: "should time each step");
    // should count records
    expect(importRes.counts[ImportFileRole.eventTypes], 3);
    expect(importRes.counts[ImportFileRole.eventCats], 2);

    final types = (await app.db.evtTypes.all()).toList();
    expect(types.map((t) => (t.id, t.name)).toSet(), {(1, "tA"), (3, "tB"), (4, "tC")});
  });
}
