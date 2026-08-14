import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/blob_repos.dart';
import 'package:flutter/material.dart';

/// Displays a BlobSchema and data that belongs to it
class BlobSchemaShowVm extends ChangeNotifier {
  final BlobSchemaRec schema;
  final BlobRepo repo;

  // --- Loaded data ---
  Map<String, Set<String>>? enumGroupValues;

  // TODO: Paginate to avoid loading all records?
  List<UserBlobRec>? records;

  BlobSchemaShowVm(this.schema, this.repo);

  Future<void> load() async {
    // load corresponding data
    records = (await repo.bySchema(schema.id)).toList();

    notifyListeners();
  }
}
