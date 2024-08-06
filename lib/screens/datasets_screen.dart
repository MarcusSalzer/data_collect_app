import 'dart:async';

import 'package:data_collector_app/io_util.dart';
import 'package:flutter/material.dart';

// TODO: support types of datasets: continous time, daily etc

class DatasetsScreen extends StatefulWidget {
  const DatasetsScreen({super.key});

  @override
  State<DatasetsScreen> createState() => _DatasetsScreenState();
}

class _DatasetsScreenState extends State<DatasetsScreen> {
  late Future<List> _index;

  @override
  void initState() {
    super.initState();
    _index = loadDataIndex();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 100, right: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Datasets",
            style: TextStyle(fontSize: 30),
          ),
          Expanded(
            child: FutureBuilder(
                future: _index,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return const Text("Error loading datasets");
                    }
                    var indexData = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: indexData.length,
                      itemBuilder: (context, index) {
                        return datasetTile(indexData[index]);
                      },
                    );
                  } else {
                    return const Text("Loading...");
                  }
                }),
          ),
        ],
      ),
    );
  }

  ListTile datasetTile(Map dataset) {
    return ListTile(
      leading: const Icon(Icons.list),
      title: Text(dataset["name"]),
    );
  }
}
