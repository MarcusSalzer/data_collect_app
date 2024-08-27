import 'package:data_collector_app/data_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'history_list_tile.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<DataModel>(
        builder: (context, dataProvider, child) {
          if (dataProvider.currentData.isEmpty) {
          return const Center(
            child: Text("Dataset is empty."),
          );
        }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: dataProvider.currentData.length,
                  itemBuilder: (context, index) {
                    return HistoryListTile(dataSamp: dataProvider.currentData[index]);
                  },
                ),
              ),
              Text("Total samples: ${dataProvider.currentData.length}")
            ],
          );
        },
      ),
    );
  }
}
