import 'dart:io';

import 'package:data_collector_app/io_util.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Provide data specific to one dataset.
class DataProviderCol extends ChangeNotifier {
  Map<String, dynamic>? _datasetInfo;
  Map<String, List<dynamic>>? _data;

  Map get schema {
    return _datasetInfo?["schema"] ?? (throw NoSchemaException());
  }

  String get name {
    return _datasetInfo?["name"] ?? (throw NoDatasetException());
  }

  Map<String, List<dynamic>> get data => _data ?? {};

  Future<void> chooseDataset(Map<String,dynamic> dataset){
    return Future.delayed(const Duration(milliseconds: 100),null);
  }

  Future<void> loadDataCsv() async {
    if (_datasetInfo == null) {
      throw NoDatasetException();
    }

    var dir = await FolderHelper.getDataDir();
    var file = File(p.join(dir.path, "$name.csv"));

    _data = {for (var key in schema.keys) key: []};

    if (await file.exists()) {
      for(var line in await file.readAsLines()){
        line.split(",");
      }

    }
  }
}



// exceptions
class NoDatasetException implements Exception {
  String get message => "No dataset info provided. Cannot load data.";
}

class NoSchemaException implements Exception {
  String get message => "No schema provided. Cannot parse data.";
}

class InvalidSchemaException implements Exception {
  String get message => "Invalid schema. Cannot parse data.";
}

class InvalidDataException implements Exception {
  String get message => "Invalid data. Cannot parse.";
}
