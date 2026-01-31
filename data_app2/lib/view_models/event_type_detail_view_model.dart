import 'package:data_app2/app_state.dart';
import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/errors/db_ref_exists_error.dart';
import 'package:data_app2/util/colors.dart';
import 'package:isar_community/isar.dart';

class EventTypeDetailViewModel extends EditVm<EvtTypeRec, EvtTypeDraft> {
  EventTypeDetailViewModel(EvtTypeRec? stored, this._app)
    : super(stored, stored?.toDraft() ?? EvtTypeDraft("[new type]"));

  // === Final refs ===
  final AppState _app;

  ColorKey get color => draft.color;

  void updateColor(ColorKey newColor) {
    draft = draft.copyWith(color: newColor);
    notifyListeners();
  }

  void updateName(String name) {
    draft.copyWith(name: name.trim());
    notifyListeners();
  }

  @override
  Future<bool> delete() async {
    final stored = this.stored;
    if (stored == null) return false; // cannot delete if never saved

    var didDelete = false;

    try {
      didDelete = await _app.db.eventTypes.forceDelete(stored.id);
      return await _app.evtTypeManager.remove(stored.id, stored.name);
    } on DbRefExistsError catch (e) {
      errorMsg = "Category ${e.id} has references, will not delete";
    }

    notifyListeners();
    return didDelete;
  }

  // save event type to DB, returns error message or null if successful
  @override
  Future<String?> save() async {
    String? message;
    try {
      if (stored case Identifiable stored) {
        // We are updating a stored record
        final updated = draft.toRec(stored.id);
        await _app.evtTypeManager.update(updated);
        stored = updated;
      } else {
        // We are creating a new record
        final newRec = draft.toRec(await _app.db.eventTypes.create(draft));
        await _app.evtTypeManager.update(newRec);
        stored = newRec;
      }
    } on IsarError catch (e) {
      if (e.message.contains("Unique")) {
        message = "Please give a unique name";
      } else {
        message = e.message;
      }
    } catch (e) {
      message = e.toString();
    }
    notifyListeners();
    return message;
  }
}
