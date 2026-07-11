import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/screens/blob_schema_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Summary screen showing info and data for this schema.
class BlobSchemaShowScreen extends StatelessWidget {
  final BlobSchemaRec rec;
  final DBService db;
  const BlobSchemaShowScreen(this.db, this.rec, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(rec.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, semanticLabel: "edit"),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => BlobSchemaEditScreen(context.read<AppState>().db, rec),
                    ),
                  )
                  .then((_) {
                    if (context.mounted) {
                      // Reload data after possible edits
                      // context.read<BlobSchemaShowVm>().load();
                    }
                  });
            },
          ),
        ],
      ),
      body: Placeholder(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          print("TODO go to data edit screen.");
        },
      ),
    );
  }
}
