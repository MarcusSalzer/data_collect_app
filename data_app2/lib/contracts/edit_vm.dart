import 'package:data_app2/contracts/data.dart';
import 'package:flutter/material.dart';

abstract class EditVm<R extends Identifiable, D extends Draft> extends ChangeNotifier {
  R? stored;
  D draft;

  String? errorMsg;

  EditVm(this.stored, this.draft);

  int? get id => stored?.id;
  bool get isDirty => stored?.toDraft() != draft;

  Future<bool> delete();
  Future<void> save();

  void dismissError() {
    errorMsg = null;
    notifyListeners();
  }
}
