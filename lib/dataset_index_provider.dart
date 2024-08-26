import 'dart:convert';
import 'dart:io';

import 'package:data_collector_app/io_util.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Provide index of all datasets
class DatasetIndexProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _datasets = [];

  List<Map<String, dynamic>> get datasets => _datasets;
  List<String> get datasetNames =>
      List<String>.of(_datasets.map((e) => e["name"]));

  Future<void> saveDatasetIndex() async {
    var dir = await FolderHelper.getDataDir();
    var file = File(p.join(dir.path, "dataset_index.json"));

    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    var contents = jsonEncode(_datasets);
    await file.writeAsString(contents);
    notifyListeners();
  }


  /// add a new dataset to index, and save.
  void addDataset(Map<String, dynamic> dataset) {
    _datasets.add(dataset);

    notifyListeners();
    saveDatasetIndex();
  }

  /// remove a dataset from index, and save.

  Future<void> deleteDataset(Map<String, dynamic> dataset) async {
    _datasets.remove(dataset);
    notifyListeners();
    saveDatasetIndex();
    moveDataToTrash(dataset["name"]);
  }

  Future<void> copyDataset(Map<String, dynamic> dataset) async {
    var i = 1;
    String name0 = dataset["name"];

    String end = name0.split("_").last;

    // if already ends with 2 digit
    if (end.length == 2 && int.tryParse(end) != null) {
      name0 = name0.substring(0, name0.length - 3);
    }

    // make new unique name
    var name = name0;
    while (datasetNames.contains(name)) {
      name = "${name0}_${i.toString().padLeft(2, "0")}";
      i++;
    }

    // add new dataset to index
    var newDataset = Map<String, dynamic>.from(dataset);
    newDataset["name"] = name;
    addDataset(newDataset);

    // copy data too
    copyDataFile(dataset["name"], newDataset["name"]);

    notifyListeners();
    await saveDatasetIndex();
  }
}
