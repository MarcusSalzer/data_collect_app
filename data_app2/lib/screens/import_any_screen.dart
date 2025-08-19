import 'package:data_app2/enums.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/import_any_model.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/style.dart';
import 'package:data_app2/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImportAnyScreen extends StatelessWidget {
  const ImportAnyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Import"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<ImportAnyModel>(
          builder: (context, model, child) {
            // Loading state
            if (model.state == ImportState.loading) {
              return Center(
                child: CircularProgressIndicator.adaptive(),
              );
            }

            // Done state
            if (model.state == ImportState.done) {
              return Column(
                children: [
                  Text("OK"),
                ],
              );
            }

            final error = model.error;
            final summary = model.summary;

            // final header = model.header;
            if (summary != null) {
              return Column(
                spacing: 30,
                children: [
                  ImportSummaryTable(
                    summary: summary,
                    path: model.filePath,
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        final count = await model.doImport();
                        if (context.mounted) {
                          simpleSnack(context, "Imported $count records");
                        }
                      },
                      child: Text("Import"))
                ],
              );
            }

            // error or unknown error
            return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("error: ${error ?? 'failed unexpectedly :('}"),
                ]);
          },
        ),
      ),
    );
  }
}

class ImportSummaryTable extends StatelessWidget {
  final ImportableSummary summary;
  final String path;
  const ImportSummaryTable({
    super.key,
    required this.path,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        Row(
          spacing: 10,
          children: [
            Expanded(
              flex: 1,
              child: Text("File:"),
            ),
            Expanded(
              flex: 4,
              child: Text(
                path,
                style: filePathText,
                softWrap: true,
              ),
            ),
          ],
        ),
        Row(
          spacing: 10,
          children: [
            Expanded(
              flex: 1,
              child: Text("Records:"),
            ),
            Expanded(
              flex: 4,
              child: Text(
                "${summary.count} (${summary.nullCount} missing values)",
                style: filePathText,
                softWrap: true,
              ),
            ),
          ],
        ),
        Row(
          spacing: 10,
          children: [
            Expanded(
              flex: 1,
              child: Text("First:"),
            ),
            Expanded(
              flex: 4,
              child: Text(
                Fmt.date(summary.earliest),
                style: filePathText,
                softWrap: true,
              ),
            ),
          ],
        ),
        Row(
          spacing: 10,
          children: [
            Expanded(
              flex: 1,
              child: Text("Last:"),
            ),
            Expanded(
              flex: 4,
              child: Text(
                Fmt.date(summary.latest),
                style: filePathText,
                softWrap: true,
              ),
            ),
          ],
        ),
        Row(
          spacing: 10,
          children: [
            Expanded(
              flex: 1,
              child: Text("Table:"),
            ),
            Expanded(
              flex: 4,
              child: Text(
                summary.mode.name,
                style: filePathText,
                softWrap: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
