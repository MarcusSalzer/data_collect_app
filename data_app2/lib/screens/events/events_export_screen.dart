import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/csv_util.dart';
import 'package:data_app2/data/evt_draft.dart';
import 'package:data_app2/view_models/event_export_view_model.dart';
import 'package:data_app2/util/process_state.dart';
import 'package:data_app2/widgets/two_columns.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Export")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ChangeNotifierProvider<EventExportViewModel>(
            create: (_) {
              final app = Provider.of<AppState>(context, listen: false);
              return EventExportViewModel(app)..load();
            },
            child: Consumer<EventExportViewModel>(
              builder: (context, vm, child) {
                final ps = vm.state;

                switch (ps) {
                  case Loading():
                    return Center(child: Text("Loading..."));
                  case Ready(:final data):
                    final adapter = vm.adapter;

                    return Column(
                      spacing: 12,
                      children: [
                        Text("Has ${data.nEvt} events | ${data.nType} types"),
                        // CsvSchemaSelector(
                        //     selectedSchema: vm.schema,
                        //     onChanged: (s) => vm.setSchema(s)),
                        Text("Example Row"),
                        ExampleRowDisplay<EvtDraft>(adapter, data.example),
                        ElevatedButton.icon(
                          onPressed: () {
                            vm.doExport();
                          },
                          label: Text("Export"),
                          icon: Icon(Icons.upload),
                        ),
                      ],
                    );
                  case Done(:final log):
                    return Column(
                      spacing: 20,
                      children: [
                        Text(
                          "Export completed",
                          style: TextStyle(fontSize: 20),
                        ),
                        if (log != null)
                          SingleChildScrollView(
                            child: Column(
                              spacing: 12,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: log.map((e) => Text(e)).toList(),
                            ),
                          ),
                      ],
                    );
                  case Error(:final error):
                    return Center(child: Text(error.toString()));
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ExampleRowDisplay<T> extends StatelessWidget {
  final T example;
  final CsvAdapter<T> adapter;
  const ExampleRowDisplay(this.adapter, this.example, {super.key});

  @override
  Widget build(BuildContext context) {
    final values = adapter.toRow(example).split(adapter.sep);
    final cols = adapter.cols;

    if (values.length != cols.length) {
      return Text(
        "CSV adapter error",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      );
    }
    return TwoColumns(
      flex: (2, 3),
      rows: cols.indexed
          .map(
            (e) => (
              Text(e.$2),
              Text(values[e.$1], style: TextStyle(fontFamily: "monospace")),
            ),
          )
          .toList(),
    );
  }
}

// class CsvSchemaSelector extends StatelessWidget {
//   final SchemaLevel selectedSchema;
//   final ValueChanged<SchemaLevel> onChanged;

//   const CsvSchemaSelector({
//     super.key,
//     required this.selectedSchema,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Select Export Schema:",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         const Text("Note: only raw can be imported in app"),
//         ...SchemaLevel.values.map((schema) {
//           return RadioListTile<SchemaLevel>(
//             title: Text(schema.name.capitalized),
//             subtitle: Text(schema.desc),
//             value: schema,
//             groupValue: selectedSchema,
//             onChanged: (value) {
//               if (value != null) onChanged(value);
//             },
//           );
//         }),
//       ],
//     );
//   }
// }
