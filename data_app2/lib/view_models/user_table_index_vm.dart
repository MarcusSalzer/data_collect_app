import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/user_schema_repos.dart';
import 'package:flutter/material.dart';

class UserTableIndexVm extends ChangeNotifier {
  UserTableIndexVm(this._repo);

  final UserTableRepo _repo;

  // data
  List<UserTableRec>? items;

  Future<void> load() async {
    items = (await _repo.all()).toList();
    notifyListeners();
  }
}
