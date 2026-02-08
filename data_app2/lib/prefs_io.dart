import 'dart:convert';
import 'dart:io';

import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/io.dart';
import 'package:path/path.dart' as p;

class PrefsIo {
  static Future<File> get defaultPrefsFile async {
    return File(p.join((await defaultInternalStoreDir()).path, "prefs.json"));
  }

  static Future<AppPrefs?> load(File prefsFile) async {
    if (await prefsFile.exists()) {
      final j = jsonDecode(await prefsFile.readAsString());
      return AppPrefs.fromJson(j);
    }
    return null;
  }

  static Future<void> store(AppPrefs prefs, File prefsFile) async {
    final prefsStr = jsonEncode(prefs.toJson());
    await prefsFile.writeAsString(prefsStr);
  }
}
