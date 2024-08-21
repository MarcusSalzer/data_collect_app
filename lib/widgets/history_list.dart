import 'package:data_collector_app/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'history_list_tile.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.data == null) {
            return const Center(
              child: Text("Loading data..."),
            );
          } else if (dataProvider.data!.isEmpty) {
            return const Center(
              child: Text("Dataset is empty."),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: dataProvider.data!.length,
                  itemBuilder: (context, index) {
                    return HistoryListTile(dataSamp: dataProvider.data![index]);
                  },
                ),
              ),
              Text("Total samples: ${dataProvider.data?.length}")
            ],
          );
        },
      ),
    );
  }
}
