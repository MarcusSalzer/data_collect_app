import 'package:data_app2/app_state.dart';
import 'package:data_app2/colors.dart';
import 'package:data_app2/user_events.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class EventTypeDetailViewModel extends ChangeNotifier {
  EvtTypeRec original;
  final EvtTypeRec typeEdit;
  final AppState _app;

  ColorKey get color => typeEdit.color;
  bool get isDirty => typeEdit != original;

  EventTypeDetailViewModel(EvtTypeRec? typeOriginal, this._app)
      : original = typeOriginal ??
            EvtTypeRec(name: "[new type]"), // temporary null object
        typeEdit = typeOriginal?.copyWith() ?? EvtTypeRec(name: "[new type]");

  updateColor(ColorKey newColor) {
    typeEdit.color = newColor;
    notifyListeners();
  }

  updateName(String name) {
    typeEdit.name = name;
    notifyListeners();
  }

  // save event type to DB, returns error message or null if successful
  Future<String?> save() async {
    String? message;
    try {
      await _app.evtTypeRepo.updateType(typeEdit);
      original = typeEdit.copyWith();
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
