import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/user_schema_repos.dart';
import 'package:flutter/material.dart';

class UserEnumIndexVm extends ChangeNotifier {
  final UserEnumRepo _repo;

  // data
  List<UserEnumRec>? items;
  UserEnumIndexVm(this._repo);

  Future<void> load() async {
    items = (await _repo.all()).toList();
    notifyListeners();
  }
}
