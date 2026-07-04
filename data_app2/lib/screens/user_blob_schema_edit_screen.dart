import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/view_models/blob_schema_edit_vm.dart';
import 'package:data_app2/widgets/edit_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class UserBlobSchemaEditScreen extends StatelessWidget {
  final BlobSchemaRec? existing;
  final DBService db;
  const UserBlobSchemaEditScreen(this.db, this.existing, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BlobSchemaEditVm>(
      create: (context) => BlobSchemaEditVm("Todo", existing)..load(),
      builder: (context, child) => EditScaffoldForVm(
        title: "blobschema edit",
        body: Placeholder(),
        vm: context.read<BlobSchemaEditVm>(),
      ),
    );
    // return EditScaffoldForVm(
    //   title: "blobSchema edit",
    // );
  }
}
