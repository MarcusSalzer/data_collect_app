import 'dart:io';

import 'package:data_collector_app/data_util.dart';
import 'package:data_collector_app/widgets/input_form_vertical.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InputScreenFormNew extends StatelessWidget {
  const InputScreenFormNew({super.key});

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
        future: Provider.of<DataModel>(context).loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text("loading..."));
          } else if (snapshot.hasError) {
            final e = snapshot.error;

            late final String msg;

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
                const Text("Error loading data!"),
                SelectionArea(child: Text(msg)),
              ],
            ));
          } else {
            return const InputFormVertical(); // Replace this with your actual content
          }
        },
      ),
    );
  }
}
