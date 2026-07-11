import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/user_enum_repos.dart';
import 'package:flutter/material.dart';

class UserEnumIndexVm extends ChangeNotifier {
  final UserEnumRepo _enumRepo;
  final UserEnumValueRepo _enumValueRepo;

  // data
  List<UserEnumRec>? enums;
  Map<int, List<UserEnumValueRec>> vmap = {};
  UserEnumIndexVm(this._enumRepo, this._enumValueRepo);

  Future<void> load() async {
    final e = await _enumRepo.all();

    // All enums
    enums = e.toList();

    // collect values (key by enum id)
    vmap.clear();
    for (var v in await _enumValueRepo.all()) {
      vmap.putIfAbsent(v.enumId, () => []).add(v);
    }

    notifyListeners();
  }
}
