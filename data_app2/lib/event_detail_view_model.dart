import 'package:data_app2/app_state.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';

/// Handle details and editing of a single event
class EventDetailViewModel extends ChangeNotifier {
  final EvtRec _evt;
  final EvtRec _original;

  final AppState _app;

  bool get isDirty => _evt != _original;

  EvtRec get evt => _evt;
  EvtTypeRec? get evtType {
    return _app.evtTypeRepo.resolveById(evt.typeId);
  }

  List<EvtTypeRec> get allTypes => _app.evtTypeRepo.all;

  EventDetailViewModel(EvtRec evt, this._app)
      : _evt = evt.copyWith(),
        _original = evt;

  /// Update the type of the event
  changeType(int newType) {
    if (newType != _evt.typeId) {
      _evt.typeId = newType;
      notifyListeners();
    }
  }

  /// update start time
  changeStartLocalTZ(DateTime dt) {
    _evt.start = LocalDateTime.fromDateTimeLocalTZ(dt);
    notifyListeners();
  }

  /// update end time
  changeEndLocalTZ(DateTime dt) {
    _evt.end = LocalDateTime.fromDateTimeLocalTZ(dt);
    notifyListeners();
  }

  /// save the event to DB if updated
  Future<bool> save() async {
    if (isDirty) {
      await _app.db.putEvent(_evt.toIsar());
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  /// delete the event from DB
  Future<bool> delete() async {
    final eId = _evt.id;
    if (eId == null) {
      return false;
    }
    final didDelete = await _app.db.deleteEvent(eId);
    return didDelete;
  }
}
