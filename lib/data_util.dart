import 'dart:convert';
import 'dart:io';

import 'package:data_collector_app/io_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class DataModel extends ChangeNotifier {
  late final Directory _dataDir;
  List<Dataset> _datasets = [];

  Dataset? _currentDataset;
  List<DataSample>? _currentData;
  bool _unsavedChanges = false;
  // bool _isLoading = true;

  List<Dataset> get datasets => _datasets;
  bool get unsavedChanges => _unsavedChanges;
  // bool get isLoading => _isLoading;

  /// get or throw [StateError].
  List<dynamic> get currentData {
    if (_currentData == null) {
      throw StateError("Data not loaded");
    }
    return _currentData!;
  }

  /// get or throw [StateError].
  Dataset get currentDataset {
    if (_currentDataset == null) {
      throw StateError("No dataset selected");
    }
    return _currentDataset!;
  }

  Future<void> init([Directory? dir]) async {
    _dataDir = dir ?? await FolderHelper.getDataDir();

    await _loadDatasetIndex();
    // _isLoading = false;
  }

  void selectDatasetAt(int index) {
    unloadData();
    _currentDataset = datasets[index];
    notifyListeners();
  }

  void addDataset(Dataset newDataset) async {
    _datasets.add(newDataset);
    _saveDatasetIndex();

    final newFile = File(p.join(_dataDir.path, "${newDataset.name}.csv"));

    await newFile.create();
    notifyListeners();
  }

  /// reset state
  void unloadData() {
    _currentDataset = null;
    _currentData = null;
    _unsavedChanges = false;

    notifyListeners();
  }

  /// Add a sample to [_currentData].
  /// Also update [currentDataset]'s length, [unsavedChanges] and notify listeners.
  ///
  /// - Note: can throw errors
  void addSample(DateTime timestamp, List<String> values) {
    currentData.add(DataSample(timestamp, _parseValues(values)));
    currentDataset.length = currentData.length;
    _unsavedChanges = true;

    notifyListeners();
  }

  /// Remove a specific sample from [_currentData], at index [index].
  /// Also updates the [currentDataset]'s length,
  /// [unsavedChanges] and notifies listeners.
  ///
  /// - Note: can throw errors.
  void removeSampleAt(int index) {
    currentData.removeAt(index);
    currentDataset.length = currentData.length;
    _unsavedChanges = true;

    notifyListeners();
  }

  Future<void> loadData() async {
    var data = <DataSample>[];
    try {
      await for (var values in streamCsv(_currentDataset!.name)) {
        data.add(DataSample(
          DateTime.parse(values.first),
          _parseValues(values.sublist(1)),
        ));
      }
    } on Exception {
      rethrow;
    }
    _currentData = data;
    // _isLoading = false;
    notifyListeners();
  }

  Future<void> saveData() async {
    final lines = _currentData!.map((DataSample sample) => sample.toString());
    await writeCsv(lines, _currentDataset!.name);
  }

  Future<void> _loadDatasetIndex() async {
    // _isLoading = true;
    var file = File(p.join(_dataDir.path, "dataset_index.json"));
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode([]));
    }
    var jsonData = jsonDecode(await file.readAsString());

    _datasets = _parseDatasets(jsonData as List<dynamic>);

    // _isLoading = false;
    notifyListeners();
  }

  List<Dataset> _parseDatasets(List data) {
    return data
        .map((item) => item as Map<String, dynamic>)
        .map((item) => Dataset(
              item["name"].toString(),
              Map<String, String>.from(item["schema"]),
              item["length"],
            ))
        .toList();
  }

  Future<void> _saveDatasetIndex() async {
    var file = File(p.join(_dataDir.path, "dataset_index.json"));

    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    var contents = jsonEncode(
      _datasets.map((item) => item.toMap()).toList(),
    );
    await file.writeAsString(contents);
    notifyListeners();
  }

  /// Parse a list of strings according to [currentDataset] schema.
  List<dynamic> _parseValues(List<String> values) {
    final dtypes = currentDataset.schema.values.toList();

    if (dtypes.length != values.length) {
      throw ArgumentError("number of values does not match schema");
    }

    var result = [];
    for (var i = 0; i < values.length; i++) {
      if (values[i].isEmpty || values[i] == "null") {
        result.add(null);
      } else {
        switch (dtypes[i]) {
          case "numeric":
            result.add(num.tryParse(values[i]));
            break;
          case "datetime":
            result.add(DateTime.tryParse(values[i]));
            break;
          default:
            result.add(values[i]);
        }
      }
    }
    return result;
  }
}

class Dataset {
  String name;
  Map<String, String> schema;
  int length;

  Dataset(this.name, this.schema, this.length);

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "schema": schema,
      "length": length,
    };
  }
}

class DataSample {
  DateTime timestamp;
  List<dynamic> data;

  DataSample(this.timestamp, this.data);

  /// format a CSV row with timestamp followed by data
  @override
  String toString() {
    return [timestamp.toString(), ...data.map((e) => e.toString())].join(",");
  }
}
