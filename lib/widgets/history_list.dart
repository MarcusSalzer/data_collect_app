import 'package:data_collector_app/utility/data_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'history_list_tile.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataModel>(
      builder: (context, model, child) {
        late final List data;
        try {
          data = model.currentData;
        } on StateError catch (e) {
          return Center(
            child: Text("Error: ${e.message}"),
          );
        }
        if (data.isEmpty) {
          return const Center(
            child: Text("Dataset is empty."),
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: model.currentData.length,
                itemBuilder: (context, index) {
                  return HistoryListTile(dataSamp: model.currentData[index]);
                },
              ),
            ),
            Text("Total samples: ${model.currentData.length}")
          ],
        );
      },
    );
  }
}
