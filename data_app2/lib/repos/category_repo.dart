import 'package:data_app2/data/evt_cat_rec.dart';
import 'package:data_app2/isar_models.dart';
import 'package:isar_community/isar.dart';

/// Persist Categories
class CategoryRepo {
  final Isar _isar;
  CategoryRepo(this._isar);

  Future<int> count() async {
    return await _isar.txn(() async {
      return await _isar.eventCategorys.count();
    });
  }

  /// Get all (as domain models)
  Future<List<EvtCatRec>> all() async {
    return (await _isar.txn(() async {
      return await _isar.eventCategorys.where().findAll();
    })).map((e) => EvtCatRec.fromIsar(e)).toList();
  }
}
