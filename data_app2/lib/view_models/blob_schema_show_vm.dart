import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/blob_repos.dart';
import 'package:data_app2/repos/user_enum_repos.dart';
import 'package:flutter/foundation.dart';

/// Displays a BlobSchema and data that belongs to it
class BlobSchemaShowVm extends ChangeNotifier {
  final BlobSchemaRec schema;
  final BlobRepo repo;
  final UserEnumRepo _enumRepo;

  // --- Loaded data ---
  Map<String, Set<String>>? enumGroupValues;

  // TODO: Paginate to avoid loading all records?
  List<UserBlobRec>? records;

  BlobSchemaShowVm(this.schema, this.repo, this._enumRepo);

  Future<void> load() async {
    // load corresponding data
    records = (await repo.bySchema(schema.id)).toList();

    notifyListeners();
  }
}
