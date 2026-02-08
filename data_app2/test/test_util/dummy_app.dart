import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/isar_models.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'paths.dart';

Future<Isar> getTmpIsar() async {
  await Isar.initializeIsarCore(download: true);

  final dir = await getTmpDir();
  final isar = await Isar.open(
    [EventSchema, PreferencesSchema, EventTypeSchema, EventCategorySchema],
    directory: dir.path,
    name: 'test_db',
  );
  return isar;
}

Future<AppState> getDummyApp() async {
  final (dir, userDir) = await tmpDirWithSubdir();

  final db = DBService(await getTmpIsar());
  final prefsFile = File(p.join((await getTmpDir()).path, "test_prefs.json"));

  return AppState(db, AppPrefs(), userDir, prefsFile);
}
