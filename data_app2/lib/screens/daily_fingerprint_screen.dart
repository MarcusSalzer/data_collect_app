import 'package:data_app2/daily_evt_summary_service.dart';
import 'package:data_app2/data/daily_evt_summary.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:flutter/material.dart';

class DailySummaryScreen extends StatelessWidget {
  final DailyEvtSummaryService summaryService;

  const DailySummaryScreen({super.key, required this.summaryService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DB Daily Summary")),
      body: FutureBuilder<List<DailyEvtSummary>>(
        future: summaryService.buildAll(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final data = snap.data ?? [];

          if (data.isEmpty) {
            return const Center(child: Text("No summary data"));
          }

          return ListView.builder(itemCount: data.length, itemBuilder: (_, i) => _SummaryTile(data[i]));
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final DailyEvtSummary s;

  const _SummaryTile(this.s);

  @override
  Widget build(BuildContext context) {
    final dur = s.totalDuration;

    return ListTile(
      dense: true,
      title: Text(Fmt.date(s.dateUtc)),
      subtitle: Text(
        "count=${s.eventCount}  "
        "dur=${Fmt.durationHmVerbose(dur)}  "
        "startΣ=${s.sumStartEpochSec}  "
        "xor=${s.xorMix.toRadixString(16)}",
      ),
    );
  }
}
