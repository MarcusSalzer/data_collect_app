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
                    return const Center(child: CircularProgressIndicator());
                    // TODO: handle loading and missing separately
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

  final Map dataset;

  @override
  Widget build(BuildContext context) {
    assert(Set.of(dataset.keys).containsAll(["name", "schema"]),
        "Missing dataset keys");

    var schemaIcons = <Widget>[];
    try {
      for (var dtype in dataset["schema"].values) {
        schemaIcons.add(switch (dtype) {
          "num" => const Icon(Icons.numbers),
          "cat" => const Icon(Icons.abc),
          _ => const Icon(Icons.question_mark),
        });
      }
    } catch (e) {
      schemaIcons.add(const Text("Missing schema"));
    }

    return ListTile(
      leading: const Icon(Icons.list),
      title: Text(dataset["name"]),
      trailing: SizedBox(
        width: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: schemaIcons,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InputScreenForm(dataset: dataset),
          ),
        );
      },
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
