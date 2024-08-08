import 'dart:convert';
import 'dart:io';

import 'package:data_collector_app/io_util.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Provide index of all datasets
class DatasetIndexProvider extends ChangeNotifier {
  List<dynamic> _datasets = [];

  List<dynamic> get datasets => _datasets;

  Future<void> saveDatasetIndex() async {
    var dir = await FolderHelper.getDataDir();
    var file = File(p.join(dir.path, "dataset_index.json"));

    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    var contents = jsonEncode(_datasets);
    await file.writeAsString(contents);
  }

  Future<void> loadDatasetIndex() async {
    var dir = await FolderHelper.getDataDir();
    var file = File(p.join(dir.path, "dataset_index.json"));
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    _datasets = jsonDecode(await file.readAsString());
    notifyListeners();
  }
}
