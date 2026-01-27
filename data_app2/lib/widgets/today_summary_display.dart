import 'package:data_app2/view_models/today_summary_vm.dart';
import 'package:data_app2/widgets/events_summary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodaySummaryDisplay extends StatelessWidget {
  const TodaySummaryDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final thm = Theme.of(context);

    return Consumer<TodaySummaryVm>(
      builder: (context, app, child) {
        final summary = app.todaySummary;
        if (summary == null) {
          return Text("loading todaySummary");
        }
        if (summary.items.isEmpty) {
          return const Center(child: Text("No events today"));
        }
        return Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.all(8),
          decoration: ShapeDecoration(
            color: thm.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(1))),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EventDurationTable(summary),
              SizedBox(height: 10),
              MultiBar.horizontal(
                sizes: summary.items.map((entry) => entry.duration.inMinutes),
                colors: summary.items.map((entry) => entry.color.inContext(context)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
