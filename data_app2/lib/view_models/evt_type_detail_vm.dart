import 'dart:ui';

import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/util/colors.dart';
import 'package:data_app2/util/enums.dart';
import 'package:isar_community/isar.dart';

class EvtTypeDetailVm extends EditVm<EvtTypeRec, EvtTypeDraft> {
  EvtTypeDetailVm(EvtTypeRec? stored, this._db, this._typeManager)
    : super(stored, stored?.toDraft() ?? EvtTypeDraft("[new type]"), _db.evtTypes);

  // === Final refs ===
  final DBService _db;
  final EvtTypeManagerPersist _typeManager;

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
    _catsById = Map.fromEntries((await _db.evtCats.all()).map((r) => MapEntry(r.id, r)));
    notifyListeners();
  }

  @override
  delete() async {
    final stored = this.stored;
    if (stored == null) return false; // cannot delete if never saved

    final r = await _db.evtTypes.deleteIfUnreferenced(stored.id);

    var didDelete = false;
    switch (r) {
      case DeleteResult.deleted:
        await _typeManager.remove(stored.id, stored.name);
        didDelete = true;
        break;
      case DeleteResult.notFound:
        errorMsg = "Error: not found";
        break;
      case DeleteResult.referenced:
        errorMsg = "Category has references, will not delete";
        break;
    }

    notifyListeners();
    return didDelete;
  }

  @override
  save() async {
    try {
      final updated = await _db.evtTypes.createOrUpdate(draft, stored?.id);
      _typeManager.upsertType(updated);
      stored = updated;
    } on IsarError catch (e) {
      if (e.message.contains("Unique")) {
        errorMsg = "Please give a unique name";
      } else {
        errorMsg = e.message;
      }
    } catch (e) {
      errorMsg = e.toString();
    }
    // always notify after
    notifyListeners();
  }
}
