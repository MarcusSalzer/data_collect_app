import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/blob_repos.dart';
import 'package:flutter/material.dart';

class BlobSchemaIndexVm extends ChangeNotifier {
  final BlobSchemaRepo _repo;

  // data
  List<BlobSchemaRec>? items;
  BlobSchemaIndexVm(this._repo);

  Future<void> load() async {
    items = (await _repo.all()).toList();
    notifyListeners();
  }
}
