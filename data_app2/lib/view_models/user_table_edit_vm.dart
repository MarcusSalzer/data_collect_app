import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';

class UserTableEditVm extends EditVm<UserTableRec, UserTableDraft> {
  final DBService _db;

  UserTableEditVm(UserTableRec? stored, this._db) : super(stored, stored?.toDraft() ?? UserTableDraft("", []));

  Future<void> load() async {
    final storedId = stored?.id;
    if (storedId == null) return;
    notifyListeners();
  }

  void setName(String v) {
    draft.name = v.trim();
    notifyListeners();
  }

  @override
  save() async {
    try {
      late int enumId;

      if (stored == null) {
        enumId = await _db.userTables.create(draft);
        stored = draft.toRec(enumId);
      } else {
        enumId = stored!.id;
        await _db.userTables.update(draft.toRec(enumId));
        stored = draft.toRec(enumId);
      }

      // sync values: delete removed, create new, update existing

      // delete any stored values that were removed

      // simpler: replace all values for this enum
      errorMsg = null;
    } catch (e) {
      errorMsg = 'Save failed: $e';
    }
    notifyListeners();
  }

  @override
  delete() async {
    final r = stored;
    if (r == null) return false;

    final result = await _db.userEnums.forceDelete(r.id);
    notifyListeners();
    return result;

    // var didDelete = false;

    // switch (result) {
    //   case DeleteResult.deleted:
    //     didDelete = true;
    //     break;
    //   case DeleteResult.referenced:
    //     errorMsg = 'Cannot delete: value is in use';
    //     break;
    //   case DeleteResult.notFound:
    //     errorMsg = 'Error: not found';
    //     break;
    // }
    // notifyListeners();
    // return didDelete;
  }
}
