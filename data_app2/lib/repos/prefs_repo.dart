import 'package:data_app2/isar_models.dart';
import 'package:isar_community/isar.dart';

/// For accessing App preference data
class PrefsRepo {
  final Isar _isar;

  PrefsRepo(this._isar);

  /// Save app preferences
  Future<void> store(Preferences p) async {
    await _isar.writeTxn(() async {
      await _isar.preferences.put(p);
    });
  }

  /// Load app preferences
  Future<Preferences?> load() async {
    final prefs = await _isar.preferences.get(0);
    return prefs;
  }
}
