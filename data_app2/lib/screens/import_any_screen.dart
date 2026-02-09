import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/view_models/import_any_vm.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/style.dart';
import 'package:data_app2/widgets/schema_display_card.dart';
import 'package:data_app2/widgets/two_columns.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImportAnyScreen extends StatelessWidget {
  final String path;

  const ImportAnyScreen(this.path, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Import")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ChangeNotifierProvider<ImportAnyVm>(
          create: (context) {
            final app = Provider.of<AppState>(context, listen: false);
            return ImportAnyVm(path, app);
          },
          child: Consumer<ImportAnyVm>(
            builder: (context, vm, child) {
              switch (vm.step) {
                case ImportStep.scanningFolder || ImportStep.importing || ImportStep.preparingModels:
                  return Center(child: Text("Loading..."));
                case ImportStep.confirmImport:
                  final foundSchema = vm.schema;
                  return Column(
                    spacing: 30,
                    children: [
                      if (foundSchema != null) SchemaDisplayCard("Found", foundSchema),
                      ElevatedButton(
                        onPressed: () async {
                          await vm.doImport();
                        },
                        child: Text("Import"),
                      ),
                    ],
                  );
                case ImportStep.done:
                  return Center(child: Text("OK"));
                default:
                  return Center(child: Text(vm.errorMsg ?? "unknown error"));
              }
            },
          ),
        ),
      ),
    );
  }
}

class ImportSummaryTable extends StatelessWidget {
  final EvtImportSummary summary;
  final String path;
  const ImportSummaryTable({super.key, required this.path, required this.summary});

  @override
  Widget build(BuildContext context) {
    return TwoColumns(
      flex: (2, 3),
      rows: [
        (Text("file"), Text(path.split("/").last, style: filePathText, softWrap: true)),
        (
          Text("Records"),
          Text("${summary.count} (${summary.nullCount} missing values)", style: filePathText, softWrap: true),
        ),
        (Text("First"), Text(Fmt.date(summary.earliest), style: filePathText, softWrap: true)),
        (Text("Last"), Text(Fmt.date(summary.latest), style: filePathText, softWrap: true)),
        (Text("Table"), Text(summary.mode.name, style: filePathText, softWrap: true)),
        (Text("Overlapping IDs"), Text(summary.idOverlapCount.toString(), style: filePathText, softWrap: true)),
      ],
    );
  }
}
