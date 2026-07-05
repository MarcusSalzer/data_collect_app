import 'package:data_app2/app_state.dart';
import 'package:data_app2/screens/blob_schema_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserBlobSchemasScreen extends StatelessWidget {
  const UserBlobSchemasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("my blob schemas"),
      ),
      body: Placeholder(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => BlobSchemaEditScreen(context.read<AppState>().db, null),
                ),
              )
              .then((_) {
                if (context.mounted) {
                  // Reload data after possible edits
                  // context.read<UserEnumIndexVm>().load();
                }
              });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
