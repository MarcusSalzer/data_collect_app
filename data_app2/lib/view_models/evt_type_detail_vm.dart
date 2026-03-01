import 'dart:ui';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/errors/db_ref_exists_error.dart';
import 'package:data_app2/util/colors.dart';
import 'package:isar_community/isar.dart';

class EvtTypeDetailVm extends EditVm<EvtTypeRec, EvtTypeDraft> {
  EvtTypeDetailVm(EvtTypeRec? stored, this._app) : super(stored, stored?.toDraft() ?? EvtTypeDraft("[new type]"));

  // === Final refs ===
  final AppState _app;

  // === State ===

  Map<int, EvtCatRec>? _catsById;
  List<EvtCatRec>? get categories => _catsById?.values.toList();
  Color get color => ColorEngine.defaultColor; // TODO both colors?
  EvtCatRec? get currentCategory => _catsById?[draft.categoryId];

  // void updateColor(ColorKey newColor) {
  //   draft.color = newColor;
  //   notifyListeners();
  // }

  void updateName(String name) {
    draft.name = name.trim();
    notifyListeners();
  }

  void updateCategory(int catId) {
    draft.categoryId = catId;
    notifyListeners();
  }

  /// Load additional needed data (Categories)
  Future<void> load() async {
    _catsById = Map.fromEntries((await _app.db.evtCats.all()).map((r) => MapEntry(r.id, r)));
    notifyListeners();
  }

  @override
  delete() async {
    final stored = this.stored;
    if (stored == null) return false; // cannot delete if never saved

    var didDelete = false;

    try {
      didDelete = await _app.db.evtTypes.deleteIfUnreferenced(stored.id);
      await _app.evtTypeManager.remove(stored.id, stored.name);
    } on DbRefExistsError catch (e) {
      errorMsg = "Category ${e.id} has references, will not delete";
    }

    notifyListeners();
    return didDelete;
  }

  // save event type to DB, returns error message or null if successful
  @override
  save() async {
    final storedId = stored?.id;

    try {
      if (storedId == null) {
        // We are creating a new record
        final newId = await _app.db.evtTypes.create(draft);
        final newRec = draft.toRec(newId);
        _app.evtTypeManager.addType(newRec);
        stored = newRec;
      } else {
        // We are updating a stored record
        final updated = draft.toRec(storedId);
        await _app.db.evtTypes.update(updated);
        _app.evtTypeManager.addType(updated);
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
}
