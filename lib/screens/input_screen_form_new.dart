import 'dart:io';

import 'package:data_collector_app/data_util.dart';
import 'package:data_collector_app/widgets/history_list.dart';
import 'package:data_collector_app/widgets/input_form_vertical.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InputScreenFormNew extends StatefulWidget {
  const InputScreenFormNew({super.key});

  @override
  State<InputScreenFormNew> createState() => _InputScreenFormNewState();
}

class _InputScreenFormNewState extends State<InputScreenFormNew> {
  late Future<bool> _isLoading;
  @override
  void initState() {
    super.initState();
    _isLoading = _loadData();
  }

  Future<bool> _loadData() async {
    await Provider.of<DataModel>(context, listen: false).loadData();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<DataModel>(
          builder: (context, model, child) {
            return Text(model.currentDataset.name);
          },
        ),
      ),
      body: FutureBuilder<void>(
        future: _isLoading,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text("loading..."));
          } else if (snapshot.hasError) {
            final e = snapshot.error;

            late final String msg;

            final textTheme = Theme.of(context).textTheme;

            if (e is PathNotFoundException) {
              msg = "Path not found: ${e.path}";
            } else if (e is FormatException) {
              msg = "Format error: ${e.message}";
            } else {
              msg = e.toString();
            }
            return Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Error loading data",
                  style: textTheme.headlineSmall,
                ),
                SelectionArea(child: Text(msg)),
              ],
            ));
          } else {
            return const Column(
              children: [
                Expanded(child: InputFormVertical()),
                Divider(),
                Text("History"),
                Expanded(
                  child: HistoryList(),
                )
              ],
            );
          }
        },
      ),
    );
  }
}
