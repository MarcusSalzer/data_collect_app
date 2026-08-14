import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/contracts/data.dart';
import 'package:flutter/material.dart';

abstract class EditVm<R extends Identifiable, D extends Draft<R>> extends ChangeNotifier {
  R? stored;
  D draft;
  CrudRepo<R, D, dynamic> repo;

  /// IDEA: By default, use force-delete, override to use some other transaction.
  // Future<bool> deleteFun(int id) => repo.forceDelete(id);

  String? errorMsg;

  EditVm(this.stored, this.draft, this.repo);

  bool get isDirty => stored?.toDraft() != draft;
  bool get hasStored => stored != null;

  Future<void> save();

  void dismissError() {
    errorMsg = null;
    notifyListeners();
  }

  Future<bool> delete() async {
    final storedId = stored?.id;

    if (storedId == null) return false;

    try {
      final r = await repo.forceDelete(storedId);
      if (r) {
        stored = null;
      }
      notifyListeners();
      return r;
    } catch (e) {
      errorMsg = 'Could not delete: $e';
      notifyListeners();
      return false;
    }
  }
}
