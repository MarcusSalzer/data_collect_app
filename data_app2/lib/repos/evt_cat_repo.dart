import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/errors/db_ref_exists_error.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/contracts/crud_repo.dart';
import 'package:isar_community/isar.dart';

/// Persist Categories
class EvtCatRepo extends CrudRepo<EvtCatRec, EvtCatDraft, EventCategory> {
  EvtCatRepo(super.isar)
    : super(
        draftToIsar: (d) => EventCategory(d.name),
        recToIsar: (r) => EventCategory(r.name)..id = r.id,
        fromIsar: (i) => EvtCatRec(i.id, i.name),
      );

  @override
  get coll => isar.eventCategorys;

  @override
  get idProp => isar.eventCategorys.where().idProperty();

  /// Delete a category, throws [DbRefExistsError] if it is referenced by some EvtType
  Future<bool> deleteIfUnreferenced(int id) async {
    // No index here yet. eventTypes is not huge so should be ok.
    if (await isar.eventTypes.filter().categoryIdEqualTo(id).findFirst() != null) {
      throw DbRefExistsError(id);
    }
    return await super.forceDelete(id);
  }
}
