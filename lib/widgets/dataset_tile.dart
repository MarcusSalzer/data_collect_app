import 'package:data_collector_app/screens/input_screen_tabs.dart';
import 'package:data_collector_app/utility/data_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DatasetTile extends StatelessWidget {
  const DatasetTile({
    super.key,
    required this.dataset,
    required this.index,
  });

  final Dataset dataset;
  final int index;

  @override
  Widget build(BuildContext context) {
    var schemaIcons = <Widget>[];
    try {
      for (var dtype in dataset.schema.values.toList()) {
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

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Provider.of<DataModel>(context, listen: false)
                  .selectDatasetAt(index);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InputScreenTabs(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(dataset.name),
                  ),
                  Text("(${dataset.length})"),
                  const VerticalDivider(),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: schemaIcons,
                    ),
                  ),
                ],
              ),
            ),
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
              onPressed: () async {
                await Provider.of<DataModel>(context, listen: false)
                    .deleteDataset(dataset);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Deleted ${dataset.name}")),
                  );
                }
              },
              child: const Text("delete"),
            ),
            MenuItemButton(
              onPressed: () async {
                print("TODO");
                // await Provider.of<DataModel>(context, listen: false)
                //     .copyDataset(dataset);

                // if (context.mounted) {
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(content: Text("Copied ${dataset['name']}")),
                //   );
                // }
              },
              child: const Text("copy"),
            ),
          ],
        )
      ],
    );
  }
}
