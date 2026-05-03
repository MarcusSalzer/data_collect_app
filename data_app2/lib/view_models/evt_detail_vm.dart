import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/repos/evt_repo.dart';
import 'package:isar_community/isar.dart';

/// Handle details and editing of a single event
class EvtDetailVm extends EditVm<EvtRec, EvtDraft> {
  EvtDetailVm(EvtRec stored, this._evtRepo, this._typMan) : super(stored, stored.toDraft());

  final EvtRepo _evtRepo;
  final EvtTypeManager _typMan;

  EvtTypeRec? get evtType {
    return _typMan.typeFromId(draft.typeId);
  }

  List<EvtTypeRec> get allTypes => _typMan.allTypes;

  /// Update the type of the event
  void changeType(int newType) {
    if (newType != draft.typeId) {
      draft.typeId = newType;
      notifyListeners();
    }
  }

  /// Update the location of the event
  void changeLocation(LocationRec? v) {
    if (v?.id != draft.locationId) {
      draft.locationId = v?.id;
      notifyListeners();
    }
  }

  /// update start time
  void changeStartLocalTZ(DateTime dt) {
    draft.start = LocalDateTime.fromLocal(dt);
    notifyListeners();
  }

  /// update end time
  void changeEndLocalTZ(DateTime dt) {
    draft.end = LocalDateTime.fromLocal(dt);
    notifyListeners();
  }

  /// save the event to DB if updated
  @override
  save() async {
    final storedId = stored?.id;
    try {
      if (storedId == null) {
        // Store new
        final newId = await _evtRepo.create(draft);
        stored = draft.toRec(newId);
      } else {
        // Update stored
        final updated = draft.toRec(storedId);
        await _evtRepo.update(updated);
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

  /// delete the event from DB
  @override
  delete() async {
    final storedId = stored?.id;
    if (storedId == null) {
      return false;
    }
    final didDelete = await _evtRepo.forceDelete(storedId);
    return didDelete;
  }
}
