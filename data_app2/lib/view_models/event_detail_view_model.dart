import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_rec.dart';
import 'package:data_app2/data/evt_type_rec.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:flutter/material.dart';

/// Handle details and editing of a single event
class EventDetailViewModel extends ChangeNotifier {
  final EvtRec _evt;
  final EvtRec _original;

  final AppState _app;

  bool get isDirty => _evt != _original;

  EvtRec get evt => _evt;
  EvtTypeRec? get evtType {
    return _app.evtTypeManager.resolveById(evt.typeId);
  }

  List<EvtTypeRec> get allTypes => _app.evtTypeManager.all;

  EventDetailViewModel(EvtRec evt, this._app) : _evt = evt.copyWith(), _original = evt;

  /// Update the type of the event
  void changeType(int newType) {
    if (newType != _evt.typeId) {
      _evt.typeId = newType;
      notifyListeners();
    }
  }

  /// update start time
  void changeStartLocalTZ(DateTime dt) {
    _evt.start = LocalDateTime.fromDateTimeLocalTZ(dt);
    notifyListeners();
  }

  /// update end time
  void changeEndLocalTZ(DateTime dt) {
    _evt.end = LocalDateTime.fromDateTimeLocalTZ(dt);
    notifyListeners();
  }

  /// save the event to DB if updated
  Future<bool> save() async {
    if (isDirty) {
      await _app.db.events.put(_evt.toIsar());
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
    final didDelete = await _app.db.events.delete(eId);
    return didDelete;
  }
}
