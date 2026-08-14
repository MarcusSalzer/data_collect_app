import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';

class UserEnumEditVm extends EditVm<UserEnumRec, UserEnumDraft> {
  final DBService _db;
  UserEnumEditVm(UserEnumRec? stored, this._db) : super(stored, stored?.toDraft() ?? UserEnumDraft(""), _db.userEnums);

  // load these
  // working copy: parallel list of values (unique by name)
  Set<String>? valueNameDrafts;
  // easier than comparing sets?
  bool _valuesDirty = false;

  /// Valid if it has a name, zero values is OK.
  bool get isValid => draft.name.isNotEmpty;

  @override
  bool get isDirty => isValid && (super.isDirty || _valuesDirty);

  /// Load the corresponding EnumValues if we have a stored record.
  Future<void> load() async {
    if (stored?.id case int id) {
      final valuesStored = await _db.userEnumValues.bySingleEnum(id);
      valueNameDrafts = valuesStored.map((v) => v.name).toSet();
    } else {
      // new enum, no values
      valueNameDrafts = {};
    }
    notifyListeners();
  }

  void setName(String v) {
    draft.name = v.trim();
    notifyListeners();
  }

  void addValue(String name) {
    _valuesDirty = true;

    // add if set is loaded
    final ok = valueNameDrafts?.add(name.trim()) ?? false; // enumId set on save

    if (!ok) {
      errorMsg = "could not add '$name'";
    }
    notifyListeners();
  }

  void removeValue(String name) {
    _valuesDirty = true;
    final ok = valueNameDrafts?.remove(name) ?? false;
    if (!ok) {
      errorMsg = "could not remove '$name'";
    }
    notifyListeners();
  }

  @override
  Future<void> save() async {
    try {
      var storedEnumId = stored?.id;

      if (storedEnumId == null) {
        storedEnumId = await _db.userEnums.create(draft);
        stored = draft.toRec(storedEnumId);
      } else {
        await _db.userEnums.update(draft.toRec(storedEnumId));
        stored = draft.toRec(storedEnumId);
      }

      // fresh list of what is stored
      final valuesStored = await _db.userEnumValues.bySingleEnum(storedEnumId);

      // sync values: delete removed, create new, update existing
      final storedValIds = valuesStored.map((v) => v.id).toSet();

      // simply replace all values for this enum
      // TODO AVOID Wasting db Ids?
      for (final id in storedValIds) {
        await _db.userEnumValues.forceDelete(id);
      }
      final newValues = valueNameDrafts?.map((n) => UserEnumValueDraft(storedEnumId!, n)).toList();
      if (newValues != null) {
        await _db.userEnumValues.createAll(newValues);
      }

      errorMsg = null;
    } catch (e) {
      errorMsg = 'Save failed: $e';
    }
    notifyListeners();
  }
}
