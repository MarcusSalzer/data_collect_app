import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/duration_summary_display_vm.dart';
import 'package:flutter/material.dart';

class SummaryModeSegmButton extends StatelessWidget {
  final DurationSummaryDisplayVm vm;

  const SummaryModeSegmButton(this.vm, {super.key});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SummaryMode>(
      style: SegmentedButton.styleFrom(side: BorderSide(color: const Color.fromARGB(0, 47, 47, 47))),
      segments: const [
        ButtonSegment(value: SummaryMode.type, label: Text("Type")),
        ButtonSegment(value: SummaryMode.category, label: Text("Category")),
      ],
      selected: {vm.summaryMode},
      onSelectionChanged: (selection) {
        vm.setSummaryMode(selection.first);
      },
      showSelectedIcon: false,
    );
  }
}
