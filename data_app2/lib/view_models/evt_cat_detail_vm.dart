import 'dart:ui';

import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/errors/db_ref_exists_error.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';
import 'package:isar_community/isar.dart';

/// View model with logic for creatign/updating/deleting a EvtCat
class EvtCatDetailVm extends EditVm<EvtCatRec, EvtCatDraft> {
  EvtCatDetailVm(EvtCatRec? stored, this._db) : super(stored, stored?.toDraft() ?? EvtCatDraft("[new cat]"));

  // === Final refs ===
  final DBService _db;

  bool get isDefault => stored?.id == EvtCatRepo.defaultId;

  @override
  Future<bool> delete() async {
    final storedId = stored?.id;
    if (storedId == null) return false; // cannot delete if never saved

    var didDelete = false;

    try {
      didDelete = await _db.evtCats.deleteIfUnreferenced(storedId);
    } on DbRefExistsError {
      errorMsg = "Category has references, will not delete";
    }

    notifyListeners();
    return didDelete;
  }

  /// try to save event type to DB
  @override
  save() async {
    final storedId = stored?.id;
    try {
      if (storedId == null) {
        // Store new
        final newId = await _db.evtCats.create(draft);
        stored = draft.toRec(newId);
      } else {
        // Update stored
        final updated = draft.toRec(storedId);
        await _db.evtCats.update(updated);
        stored = updated;
      }
    } on IsarError catch (e) {
      if (e.message.contains("Unique")) {
        errorMsg = "Please give a unique name";
      } else {
        errorMsg = e.message;
      }
    } catch (e) {
      errorMsg = e.toString();
    }
    notifyListeners();
  }

  // === Specific methods ===

  void updateName(String value) {
    draft.name = value.trim();
    notifyListeners();
  }

  void updateColor(Color value) {
    draft.color = value;
    notifyListeners();
  }

  Future<void> reload() async {
    final storedId = stored?.id;
    stored = (storedId != null) ? await _db.evtCats.getById(storedId) : null;
    notifyListeners();
  }
}
