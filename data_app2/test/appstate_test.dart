import 'package:data_app2/app_state.dart';
import 'package:data_app2/prefs_io.dart';
import 'package:data_app2/style.dart';
import 'package:test/test.dart';
import 'test_util/dummy_app.dart';

void main() {
  late final AppState app;

  setUpAll(() async {
    app = await getDummyApp();
  });

  group("preferences", () {
    test('can set colorscheme', () async {
      for (var c in ColorSchemeMode.values) {
        await app.setColorScheme(c);
        expect(app.prefs.colorSchemeMode, c);
        expect((await PrefsIo.load(app.prefsFile))?.colorSchemeMode, c);
      }
    });
  });
}
