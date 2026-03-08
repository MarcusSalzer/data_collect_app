import 'package:data_app2/view_models/today_summary_vm.dart';
import 'package:data_app2/widgets/events_summary.dart';
import 'package:data_app2/widgets/summary_mode_segm_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodaySummaryDisplay extends StatelessWidget {
  const TodaySummaryDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final thm = Theme.of(context);

    final vm = context.watch<TodaySummaryDisplayVm>();

    final summary = vm.activeSummary;
    if (summary == null) {
      return Center(child: Text("loading todaySummary"));
    }
    if (summary.items.isEmpty) {
      return const Center(child: Text("No events today"));
    }
    return Container(
      padding: EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: thm.colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(1))),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          EventDurationTable(summary, SummaryModeSegmButton(vm)),
          SizedBox(height: 10),
          MultiBar(
            sizes: summary.items.map((entry) => entry.duration.inMinutes),
            colors: summary.items.map((entry) => entry.color).toList(),
          ),
        ],
      ),
    );
  }
}
