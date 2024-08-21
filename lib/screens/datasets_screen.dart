import 'package:data_collector_app/dataset_index_provider.dart';
import 'package:data_collector_app/screens/create_dataset_screen.dart';
import 'package:data_collector_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/dataset_tile.dart';

class DatasetsScreen extends StatefulWidget {
  const DatasetsScreen({super.key});

  @override
  State<DatasetsScreen> createState() => _DatasetsScreenState();
}

class _DatasetsScreenState extends State<DatasetsScreen> {
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
      body: Padding(
        padding: const EdgeInsets.only(left: 100, right: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Consumer<DatasetIndexProvider>(
                builder: (context, datasetProvider, child) {
                  var datasets = datasetProvider.datasets;
                  if (datasets.isEmpty) {
                    return const Center(child: Text("No datasets"));
                  }
                  return ListView.builder(
                    itemCount: datasets.length,
                    itemBuilder: (context, index) {
                      return DatasetTile(dataset: datasets[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
