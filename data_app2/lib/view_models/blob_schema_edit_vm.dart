import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/user_schema.dart';

class BlobSchemaEditVm extends EditVm<BlobSchemaRec, BlobSchemaDraft> {
  final String repo;

  BlobSchemaEditVm(this.repo, BlobSchemaRec? existing)
    : super(existing, existing?.toDraft() ?? BlobSchemaDraft('', fields: []));
  Future<void> load() async {
    print("load");
    notifyListeners();
  }

  @override
  Future<bool> delete() {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<void> save() {
    // TODO: implement save
    throw UnimplementedError();
  }
}
