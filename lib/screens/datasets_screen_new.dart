import 'package:data_collector_app/data_util.dart';
import 'package:data_collector_app/widgets/dataset_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'create_dataset_screen.dart';
import 'settings_screen.dart';

class DatasetsScreenNew extends StatelessWidget {
  const DatasetsScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Datasets"),
        actions: [
          TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text("Settings")),
          TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateDatasetScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("New dataset")),
        ],
      ),
      body: Consumer<DataModel>(builder: (context, model, child) {
        return ListView.builder(
            itemCount: model.datasets.length,
            itemBuilder: (context, index) {
              return DatasetTile(
                dataset: model.datasets[index],
                index: index,
              );
            });
      }),
    );
  }
}
