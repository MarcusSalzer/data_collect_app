import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';

class UserEnumEditVm extends EditVm<UserEnumRec, UserEnumDraft> {
  final DBService _db;

  // working copy: parallel list of drafts
  List<UserEnumValueDraft> valueDrafts = [];

  UserEnumEditVm(UserEnumRec? stored, this._db) : super(stored, stored?.toDraft() ?? UserEnumDraft(""));

  /// Load the corresponding EnumValues if we have a stored record.
  Future<void> load() async {
    final storedId = stored?.id;
    if (storedId == null) return;

    final storedValues = await _db.userEnumValues.byEnum(storedId);
    valueDrafts = storedValues.map((v) => v.toDraft()).toList();
    notifyListeners();
  }

  void setName(String v) {
    draft.name = v.trim();
    notifyListeners();
  }

  void addValue(String name) {
    valueDrafts.add(UserEnumValueDraft(0, name.trim())); // enumId set on save
    notifyListeners();
  }

  void removeValue(int index) {
    valueDrafts.removeAt(index);
    notifyListeners();
  }

  void renameValue(int index, String name) {
    valueDrafts[index].name = name.trim();
    notifyListeners();
  }

  @override
  save() async {
    try {
      var storedEnumId = stored?.id;

      if (storedEnumId == null) {
        storedEnumId = await _db.userEnums.create(draft);
        stored = draft.toRec(storedEnumId);
      } else {
        await _db.userEnums.update(draft.toRec(storedEnumId));
        stored = draft.toRec(storedEnumId);
      }
      final storedValues = await _db.userEnumValues.byEnum(storedEnumId);

      // sync values: delete removed, create new, update existing
      final storedIds = storedValues.map((v) => v.id).toSet();

      // simpler: replace all values for this enum
      for (final id in storedIds) {
        await _db.userEnumValues.forceDelete(id);
      }
      for (final d in valueDrafts) {
        d.enumId = storedEnumId;
        await _db.userEnumValues.create(d);
      }

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
