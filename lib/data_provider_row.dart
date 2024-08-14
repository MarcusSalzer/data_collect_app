import 'dart:io';

import 'package:data_collector_app/io_util.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Provide data specific to one dataset.
class DataProviderRow extends ChangeNotifier {
  Map<String, dynamic>? _datasetInfo;
  List<List<dynamic>>? data;

  Map get schema {
    return _datasetInfo?["schema"] ?? (throw NoSchemaException());
  }

  String get name {
    return _datasetInfo?["name"] ?? (throw NoDatasetException());
  }

  List get dtypes => List<String>.from(schema.values);

  List<dynamic> _parseValues(List<String> values) {
    var result = [];
    for (var i = 0; i < values.length; i++) {
      if (values[i].isEmpty) {
        result.add(null);
      } else {
        switch (dtypes[i]) {
          case "numeric":
            result.add(num.parse(values[i]));
            break;
          case "datetime":
            result.add(DateTime.parse(values[i]));
            break;
          default:
            result.add(values[i]);
        }
      }
    }
    return result;
  }

  void chooseDataset(Map<String, dynamic> dataset) {
    // unload previous data
    data = null;
    _datasetInfo = dataset;
    print("chose dataset ${dataset['name']}");
    loadDataCsv();
  }

  Future<void> loadDataCsv() async {
    // Artificial delay
    print("ARTIFICIAL DELAY!");
    await Future.delayed(const Duration(seconds: 1), null);
    var dir = await FolderHelper.getDataDir();
    var file = File(p.join(dir.path, "$name.csv"));

    var fieldNames = List<String>.from(schema.keys);
    var dtypes = List<String>.from(schema.values);

    if (await file.exists()) {
      List<List<dynamic>> rows = [];
      for (var line in await file.readAsLines()) {
        var values = line.split(",");
        if (values.length != fieldNames.length) {
          throw InvalidDataException(
              "incorrect number of columns (${values.length})");
        }
        rows.add(_parseValues(values));
      }

      data = rows;
    } else {
      data = [];
    }
    notifyListeners();
  }

  /// parse values and add to dataset
  void addSample(List<String> sampleTexts) {
    data ??= [];
    data?.add(_parseValues(sampleTexts));

    notifyListeners();
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
  final String details;
  InvalidDataException([this.details = ""]);

  String get message => "Invalid data. $details";
}
