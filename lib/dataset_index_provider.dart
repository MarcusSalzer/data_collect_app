
import 'package:flutter/material.dart';

/// Provide index of all datasets
class DatasetIndexProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _datasets = [];

  List<Map<String, dynamic>> get datasets => _datasets;
  List<String> get datasetNames =>
      List<String>.of(_datasets.map((e) => e["name"]));

  
  
}
