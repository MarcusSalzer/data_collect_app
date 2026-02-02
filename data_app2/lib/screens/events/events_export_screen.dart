import 'package:data_app2/app_state.dart';
import 'package:data_app2/view_models/event_export_view_model.dart';
import 'package:data_app2/util/process_state.dart';
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
                    return Column(
                      spacing: 12,
                      children: [
                        Text("Has ${data.nEvt} events | ${data.nType} types"),
                        // CsvSchemaSelector(
                        //     selectedSchema: vm.schema,
                        //     onChanged: (s) => vm.setSchema(s)),
                        Text("Example Row"),
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
                        Text("Export completed", style: TextStyle(fontSize: 20)),
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
