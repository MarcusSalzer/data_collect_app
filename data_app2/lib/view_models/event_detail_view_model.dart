import 'dart:ui';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:isar_community/isar.dart';

/// Handle details and editing of a single event
class EventDetailViewModel extends EditVm<EvtRec, EvtDraft> {
  EventDetailViewModel(EvtRec stored, this._app) : super(stored, stored.toDraft());

  final AppState _app;

  Color get color => _app.colorFor(evtType);

  EvtTypeRec? get evtType {
    return _app.evtTypeManager.resolveById(draft.typeId);
  }

  List<EvtTypeRec> get allTypes => _app.evtTypeManager.allTypes;

  /// Update the type of the event
  void changeType(int newType) {
    if (newType != draft.typeId) {
      draft.typeId = newType;
      notifyListeners();
    }
  }

  /// update start time
  void changeStartLocalTZ(DateTime dt) {
    draft.start = LocalDateTime.fromDateTimeLocalTZ(dt);
    notifyListeners();
  }

  /// update end time
  void changeEndLocalTZ(DateTime dt) {
    draft.end = LocalDateTime.fromDateTimeLocalTZ(dt);
    notifyListeners();
  }

  /// save the event to DB if updated
  @override
  save() async {
    final storedId = stored?.id;
    try {
      if (storedId == null) {
        // Store new
        final newId = await _app.db.evts.create(draft);
        stored = draft.toRec(newId);
      } else {
        // Update stored
        final updated = draft.toRec(storedId);
        await _app.db.evts.update(updated);
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
  Future<bool> delete() async {
    final storedId = stored?.id;
    if (storedId == null) {
      return false;
    }
    final didDelete = await _app.db.evts.forceDelete(storedId);
    return didDelete;
  }

  @override
  String? get errorMsg => throw UnimplementedError();
}
