import 'package:data_collector_app/data_provider.dart';
import 'package:data_collector_app/dataset_index_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/history_list.dart';
import '../widgets/input_form.dart';

class InputScreenForm extends StatefulWidget {
  final Map<String, dynamic> dataset;
  const InputScreenForm({super.key, required this.dataset});

  @override
  State<InputScreenForm> createState() => _InputScreenFormState();
}

class _InputScreenFormState extends State<InputScreenForm> {
  late final DataProvider _dataProvider;
  late final DatasetIndexProvider _datasetIndexProvider;

  @override
  void initState() {
    super.initState();
    _dataProvider = Provider.of<DataProvider>(context, listen: false);
    _datasetIndexProvider =
        Provider.of<DatasetIndexProvider>(context, listen: false);
  }

  void _save() async {
    await _dataProvider.saveDataCsv();
    final currentSet = _datasetIndexProvider.datasets.firstWhere(
      (dataset) => dataset["name"] == _dataProvider.name,
    );
    currentSet["length"] = _dataProvider.data!.length;
    await _datasetIndexProvider.saveDatasetIndex();
  }

  Future<void> _onExit() async {
    if (_dataProvider.unsavedChanges) {
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _onExit();
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text(widget.dataset["name"]),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                InputForm(
                  dataset: widget.dataset,
                ),
                const HistoryList(),
              ],
            ),
          )),
    );
  }
}
