import 'package:data_app2/isar_models.dart';
import 'package:isar_community/isar.dart';

import 'paths.dart';

Future<Isar> getTmpIsar() async {
  await Isar.initializeIsarCore(download: true);

  final dir = await getTmpDir();
  final isar = await Isar.open(
    [EventSchema, PreferencesSchema, EventTypeSchema],
    directory: dir.path,
    name: 'test_db',
  );
  return isar;
}
