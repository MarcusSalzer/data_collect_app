import 'package:data_app2/fmt.dart';
import 'package:data_app2/io.dart';
import 'package:flutter/material.dart';

class ImportSummaryDialog extends StatelessWidget {
  final ImportableSummary summary;
  final void Function()? callback;
  const ImportSummaryDialog(this.summary, {this.callback, super.key});

  @override
  Widget build(BuildContext context) {
    final early = dtDateFmt(summary.earliest);
    final late = dtDateFmt(summary.latest);
    return SimpleDialog(
        contentPadding: EdgeInsets.all(20),
        title: Text("Import?"),
        children: [
          Text("Events between $early and $late"),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Count"),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${summary.count}"),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (callback != null) {
                  callback!();
                }
              },
              child: Text("Import"))
        ]);
  }
}
