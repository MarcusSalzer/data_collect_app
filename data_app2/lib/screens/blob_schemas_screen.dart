import 'package:data_app2/app_state.dart';
import 'package:data_app2/screens/blob_edit_screen.dart';
import 'package:data_app2/screens/blob_schema_edit_screen.dart';
import 'package:data_app2/screens/blob_schema_show_screen.dart';
import 'package:data_app2/view_models/blob_schema_index_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _Body extends StatelessWidget {
  const _Body();
  @override
  Widget build(BuildContext context) {
    final indexVm = context.watch<BlobSchemaIndexVm>();

    final items = indexVm.items;
    if (items == null) {
      return Center(child: Text("Loading..."));
    }
    if (items.isEmpty) {
      return Center(child: Text("No schemas"));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final schema = items[i];

        final fieldLines = schema.fields.entries
            .map(
              (e) => SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: TextStyle(fontFamily: "monospace")),
                    Text(e.value.toString(), style: TextStyle(fontFamily: "monospace")),
                  ],
                ),
              ),
            )
            .toList();

        final evtLink = schema.evtLink;

        fieldLines.add(
          SizedBox(
            width: double.infinity,
            child: Wrap(
              children: [
                (evtLink == null)
                    ? Text(
                        "No event link",
                        style: TextStyle(fontStyle: FontStyle.italic, fontFamily: "monospace", color: Colors.grey),
                      )
                    : Text(
                        evtLink.toString(),
                        style: TextStyle(fontFamily: "monospace"),
                      ),
              ],
            ),
          ),
        );

        return ListTile(
          title: Text(
            schema.name,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              // Show a row per field
              children: fieldLines,
            ),
          ),
          onTap: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (_) => BlobSchemaShowScreen(context.read<AppState>().db, schema),
                  ),
                )
                .then((_) {
                  if (context.mounted) {
                    // Reload data after possible edits
                    context.read<BlobSchemaIndexVm>().load();
                  }
                });
          },
          trailing: IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => BlobEditScreen(schema, null),
                    ),
                  )
                  .then((_) {
                    if (context.mounted) {
                      // Reload data after possible edits
                      context.read<BlobSchemaIndexVm>().load();
                    }
                  });
            },
          ),
        );
      },
    );
  }
}

class BlobSchemasScreen extends StatelessWidget {
  const BlobSchemasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctxCreate) {
        final app = ctxCreate.read<AppState>();
        return BlobSchemaIndexVm(app.db.blobSchemas)..load();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final count = context.watch<BlobSchemaIndexVm>().items?.length;
              return Text("Blob schemas ($count)");
            },
          ),
        ),
        body: _Body(),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
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
                        context.read<BlobSchemaIndexVm>().load();
                      }
                    });
              },
              child: Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}
