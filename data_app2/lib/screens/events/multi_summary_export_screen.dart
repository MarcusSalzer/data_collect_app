import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/period_agg_csv_writer.dart';
import 'package:data_app2/data/summary_with_period_aggs.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class MultiSummaryExportScreen extends StatefulWidget {
  final SummaryWithPeriodAggs summary;

  const MultiSummaryExportScreen(this.summary, {super.key});

  @override
  State<MultiSummaryExportScreen> createState() =>
      _MultiSummaryExportScreenState();
}

class _MultiSummaryExportScreenState extends State<MultiSummaryExportScreen> {
  String? name;
  bool includeSuffix = true;

  String get suffix => "_${widget.summary.f.name}";

  @override
  void initState() {
    final types = widget.summary.typeRecs;
    // default name if single type
    name = types.length == 1 ? types.first.name : null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context, listen: false);

    final pickedName = name;
    return Scaffold(
      appBar: AppBar(title: Text("Export summary (${widget.summary.f.name})")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              "From ${Fmt.date(widget.summary.start)} to ${Fmt.date(widget.summary.end)}",
            ),
            Text(
              "${widget.summary.aggs.length} records, ${widget.summary.nTypes} types",
            ),
            Divider(),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (value) => setState(() {
                      if (value.trim().isNotEmpty) {
                        name = value.trim();
                      } else {
                        name = null;
                      }
                    }),
                  ),
                ),
                SizedBox.fromSize(
                  size: Size(80, 30),
                  child: Center(
                    child: Text(
                      suffix,
                      style: TextStyle(
                        color: includeSuffix ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                Checkbox(
                  value: includeSuffix,
                  onChanged: (_) => setState(() {
                    includeSuffix = !includeSuffix;
                  }),
                ),
              ],
            ),
            ElevatedButton(
              // can export if name given
              onPressed: pickedName == null
                  ? null
                  : () async {
                      final dir = await app.storeSubdir("summary");
                      final file = File(p.join(dir.path, pickedName + suffix));
                      // TODO: only tot-writer right now
                      final writer = PeriodAggTotCsvWriter(widget.summary.f);
                      final lines = writer.encodeRowsWithHeader(
                        widget.summary.aggs,
                      );
                      await file.writeAsString(lines.join("\n"));

                      if (context.mounted) {
                        simpleSnack(context, "wrote ${lines.length} lines");
                        Navigator.of(context).pop();
                      }
                    },
              child: Text("Export"),
            ),
          ],
        ),
      ),
    );
  }
}
