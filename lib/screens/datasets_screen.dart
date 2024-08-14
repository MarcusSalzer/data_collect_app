import 'package:data_collector_app/data_provider_row.dart';

import 'package:data_collector_app/dataset_index_provider.dart';
import 'package:data_collector_app/screens/create_dataset_screen.dart';
import 'package:data_collector_app/screens/input_screen_form.dart';
import 'package:data_collector_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class DatasetTile extends StatelessWidget {
  const DatasetTile({
    super.key,
    required this.dataset,
  });

  final Map<String, dynamic> dataset;

  _deleteDataset(Map<String, dynamic> dataset, BuildContext context) async {
    Provider.of<DatasetIndexProvider>(context, listen: false)
        .deleteDataset(dataset)
        .then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("deleted ${dataset['name']}")),
      );
      print("done");
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(Set.of(dataset.keys).containsAll(["name", "schema"]),
        "Missing dataset keys");

    var schemaIcons = <Widget>[];
    try {
      for (var dtype in dataset["schema"].values) {
        schemaIcons.add(switch (dtype) {
          "numeric" => const Icon(Icons.numbers),
          "categoric" => const Icon(Icons.category),
          "text" => const Icon(Icons.abc),
          "datetime" => const Icon(Icons.timer),
          _ => const Icon(Icons.question_mark),
        });
      }
    } catch (e) {
      schemaIcons.add(const Text("Missing schema"));
    }

    return InkWell(
      onTap: () {
        Provider.of<DataProviderRow>(context, listen: false)
            .chooseDataset(dataset);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InputScreenForm(dataset: dataset),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(dataset["name"]),
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: schemaIcons,
              ),
            ),
            MenuAnchor(
              builder: (context, controller, child) {
                return IconButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  icon: const Icon(Icons.more_horiz),
                );
              },
              menuChildren: [
                MenuItemButton(
                  onPressed: () {
                    _deleteDataset(dataset, context);
                  },
                  child: const Text("delete"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class DatasetsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DatasetsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text("Datasets"));
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
