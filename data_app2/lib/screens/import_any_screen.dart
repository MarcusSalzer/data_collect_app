import 'package:data_app2/app_state.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/import_any_view_model.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/process_state.dart';
import 'package:data_app2/style.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/widgets/two_columns.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImportAnyScreen extends StatelessWidget {
  final String path;

  const ImportAnyScreen(this.path, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Import"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ChangeNotifierProvider<ImportAnyViewModel>(
          create: (context) {
            final app = Provider.of<AppState>(context, listen: false);
            return ImportAnyViewModel(path, app);
          },
          child: Consumer<ImportAnyViewModel>(
            builder: (context, vm, child) {
              switch (vm.state) {
                case Loading():
                  return Center(
                    child: Text("Loading..."),
                  );
                case Ready(:final data):
                  return Column(
                    spacing: 30,
                    children: [
                      ImportSummaryTable(
                        summary: data,
                        path: vm.filePath,
                      ),
                      ElevatedButton(
                          onPressed: () async {
                            final count = await vm.doImport();
                            if (context.mounted) {
                              simpleSnack(context, "Imported $count records");
                            }
                          },
                          child: Text("Import"))
                    ],
                  );
                case Done():
                  return Center(child: Text("OK"));
                case Error(:final error, :final examples):
                  if (examples != null) {
                    return Column(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(error.toString()),
                        SizedBox(
                          height: 8,
                        ),
                        ...examples.map(
                          (e) => Text(
                            e,
                            style: TextStyle(
                                fontSize: 10, fontFamily: "monospace"),
                          ),
                        )
                      ],
                    );
                  }
                  return Center(
                    child: Text(error.toString()),
                  );
              }
            },
          ),
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
    return TwoColumns(
      flex: (2, 3),
      rows: [
        (
          Text("file"),
          Text(
            path.split("/").last,
            style: filePathText,
            softWrap: true,
          )
        ),
        (
          Text("Records"),
          Text(
            "${summary.count} (${summary.nullCount} missing values)",
            style: filePathText,
            softWrap: true,
          ),
        ),
        (
          Text("First"),
          Text(
            Fmt.date(summary.earliest),
            style: filePathText,
            softWrap: true,
          )
        ),
        (
          Text("Last"),
          Text(
            Fmt.date(summary.latest),
            style: filePathText,
            softWrap: true,
          )
        ),
        (
          Text("Table"),
          Text(
            summary.mode.name,
            style: filePathText,
            softWrap: true,
          )
        ),
        (
          Text("Overlapping IDs"),
          Text(
            summary.idOverlapCount.toString(),
            style: filePathText,
            softWrap: true,
          )
        ),
      ],
    );
  }
}
