import 'package:data_collector_app/utility/data_util.dart';
import 'package:data_collector_app/widgets/history_list.dart';
import 'package:data_collector_app/widgets/input_form_verti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InputScreenTabs extends StatefulWidget {
  const InputScreenTabs({super.key});

  @override
  State<InputScreenTabs> createState() => _InputScreenTabsState();
}

class _InputScreenTabsState extends State<InputScreenTabs> {
  late Future<bool> _isLoading;
  late DataModel _model;
  @override
  void initState() {
    super.initState();
    _model = Provider.of<DataModel>(context, listen: false);
    _isLoading = _loadData();
  }

  Future<bool> _loadData() async {
    await _model.loadData();
    return true;
  }

  void _onExit() {
    if (_model.unsavedChanges) {
      _model.saveData().then((_) {
        print("saved");
      });
    } else {
      print("no changes");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _onExit();
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Consumer<DataModel>(
              builder: (context, model, child) {
                return Text("${model.currentDataset.name} (${model.currentDataset.length})");
              },
            ),
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.edit),
                  text: "Input",
                ),
                Tab(
                  icon: Icon(Icons.list),
                  text: "History",
                ),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              InputFormVertical(),
              HistoryList(),
            ],
          ),
        ),
      ),
    );
  }
}
