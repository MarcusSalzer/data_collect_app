import 'dart:io';

import 'package:data_collector_app/io_util.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Provide data specific to one dataset.
class DataProvider extends ChangeNotifier {
  Map<String, dynamic>? _datasetInfo;
  List<DataSample>? data;

  bool unsavedChanges = false;

  Map get schema {
    return _datasetInfo?["schema"] ?? (throw NoSchemaException());
  }

  String get name {
    return _datasetInfo?["name"] ?? (throw NoDatasetException());
  }

  List<String> get dtypes => List<String>.from(schema.values);

    Future<void> _loadDataCsv() async {
    // Artificial delay
    // print("ARTIFICIAL DELAY!");
    // await Future.delayed(const Duration(seconds: 2), null);
    var dir = await FolderHelper.getDataDir();
    var file = File(p.join(dir.path, "$name.csv"));

    var fieldNames = List<String>.from(schema.keys);

    if (await file.exists()) {
      List<DataSample> samples = [];
      for (var line in await file.readAsLines()) {
        var values = line.split(",");

        // should have 1 value for timestamp and rest for data.
        if (values.length != fieldNames.length + 1) {
          throw InvalidDataException(
              "incorrect number of columns (${values.length})");
        }
        samples.add(DataSample(
          DateTime.parse(values.first),
          _parseValues(values.sublist(1)),
        ));
      }

      data = samples;
    } else {
      data = [];
    }
    unsavedChanges = false;
    notifyListeners();
  }

  Future<void> saveDataCsv() async {
    // Artificial delay
    // print("ARTIFICIAL DELAY!");
    // await Future.delayed(const Duration(seconds: 2), null);
    var dir = await FolderHelper.getDataDir();
    var file = File(p.join(dir.path, "$name.csv"));

    var contents =
        data?.map((DataSample sample) => sample.toString()).join("\n");

    // create file if missing
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    if (contents != null) {
      await file.writeAsString(contents);
    }

    unsavedChanges = false;
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
