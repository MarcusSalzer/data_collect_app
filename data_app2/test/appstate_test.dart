import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/style.dart';
import 'package:test/test.dart';

import 'test_util/dummy_app.dart';
import 'test_util/paths.dart';

void main() {
  late final DBService db;
  late final AppState app;

  setUpAll(() async {
    db = DBService(await getTmpIsar());
    final (_, userDir) = await tmpDirWithSubdir();

    app = AppState(db, AppPrefs(), userDir);
    // save prefs
    await db.prefs.store(app.prefs.toIsar());
  });

  group("preferences", () {
    test('can set colorscheme', () async {
      for (var c in ColorSchemeMode.values) {
        await app.setColorScheme(c);
        expect(app.prefs.colorSchemeMode, c);
        expect((await db.prefs.load())!.colorSchemeMode, c);
      }
    });
  });
}
