import 'dart:convert';

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

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, i) {
        final r = records[i];
        return ListTile(
          title: Text(r.id.toString()),
          subtitle: Text(jsonEncode(r.values)),
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    // TODO ENUMS
                    builder: (_) => BlobEditScreen(UserBlobEditVm(r, vm.schema, enumGroupValues: {}, repo: vm.repo)),
                  ),
                )
                .then((_) {
                  if (context.mounted) {
                    // Reload data after possible edits
                    // context.read<BlobSchemaShowVm>().load();
                  }
                });
          },
        );
      },
    );
  }
}

/// Summary screen showing info and data for this schema.
class BlobSchemaShowScreen extends StatelessWidget {
  final BlobSchemaRec rec;
  final DBService db;
  const BlobSchemaShowScreen(this.db, this.rec, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BlobSchemaShowVm>(
      create: (context) => BlobSchemaShowVm(rec, db.blobs)..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(rec.name),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, semanticLabel: "edit"),
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => BlobSchemaEditScreen(db, rec),
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
        body: _BlobDataList(),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => BlobEditScreen(
                      // TODO Fix enums
                      UserBlobEditVm(null, rec, enumGroupValues: {}, repo: db.blobs),
                    ),
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
      ),
    );
  }
}
