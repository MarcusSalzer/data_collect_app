import 'package:data_app2/app_state.dart';
import 'package:data_app2/blob_validation.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/screens/blob_edit_screen.dart';
import 'package:data_app2/screens/blob_schema_edit_screen.dart';
import 'package:data_app2/view_models/blob_edit_vm.dart';
import 'package:data_app2/view_models/blob_schema_show_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _BlobDataList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BlobSchemaShowVm>();
    final records = vm.records;

    if (records == null) {
      return Center(
        child: Text("Loading..."),
      );
    }
    if (records.isEmpty) {
      return Center(
        child: Text("No records"),
      );
    }

    final thm = Theme.of(context);
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, i) {
        final r = records[i];
        return Container(
          decoration: BoxDecoration(
            border: BoxBorder.fromLTRB(bottom: BorderSide(color: thm.colorScheme.primary)),
          ),
          child: ListTile(
            title: Text(r.id.toString()),
            subtitle: _BlobSummaryTable(r, vm.schema),
            onTap: () {
              final db = context.read<AppState>().db;
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => BlobEditScreen(
                        UserBlobEditVm(r, vm.schema, db.blobs, db.userEnums, db.userEnumValues, db.evts)..load(),
                      ),
                    ),
                  )
                  .then((_) {
                    if (context.mounted) {
                      // Reload data after possible edits
                      context.read<BlobSchemaShowVm>().load();
                    }
                  });
            },
          ),
        );
      },
    );
  }
}

class _BlobSummaryTable extends StatelessWidget {
  final UserBlobRec blob;
  final BlobSchemaRec schema;

  const _BlobSummaryTable(this.blob, this.schema);
  @override
  Widget build(BuildContext context) {
    final valid = BlobValidation().validateBlob(blob, schema);

    final rows = <Widget>[];

    if (valid.excessKeys.isNotEmpty) {
      rows.add(Text("Error, excess keys: ${valid.excessKeys}"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // Show a row per field
      children: blob.values.entries.map(
        (e) {
          final err = valid.fieldErrors[e.key];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              (err == null)
                  ? Text(e.key)
                  : Text(
                      "${e.key} (${err.name})",
                      style: TextStyle(color: Colors.red),
                    ),
              Text(e.value.toString()),
            ],
          );
        },
      ).toList(),
    );
  }
}

/// Summary screen showing info and data for this schema.
class BlobSchemaShowScreen extends StatelessWidget {
  final BlobSchemaRec schema;
  final DBService db;
  const BlobSchemaShowScreen(this.db, this.schema, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BlobSchemaShowVm>(
      create: (context) => BlobSchemaShowVm(schema, db.blobs, db.userEnums)..load(),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(schema.name),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, semanticLabel: "edit"),
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => BlobSchemaEditScreen(db, schema),
                      ),
                    )
                    .then((_) {
                      if (context.mounted) {
                        // Reload data after possible edits
                        context.read<BlobSchemaShowVm>().load();
                      }
                    });
              },
            ),
          ],
        ),
        body: _BlobDataList(),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => BlobEditScreen(
                      UserBlobEditVm(null, schema, db.blobs, db.userEnums, db.userEnumValues, db.evts)..load(),
                    ),
                  ),
                )
                .then((_) {
                  if (context.mounted) {
                    // Reload data after possible edits
                    context.read<BlobSchemaShowVm>().load();
                  }
                });
          },
        ),
      ),
    );
  }
}
