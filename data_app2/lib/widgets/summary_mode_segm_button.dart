import 'package:data_app2/util/enums.dart';
import 'package:flutter/material.dart';

class SummaryModeSegmButton extends StatelessWidget {
  final SummaryMode initValue;
  final void Function(SummaryMode) onSelect;

  const SummaryModeSegmButton(this.initValue, this.onSelect, {super.key});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SummaryMode>(
      style: SegmentedButton.styleFrom(side: BorderSide(color: const Color.fromARGB(0, 47, 47, 47))),
      segments: const [
        ButtonSegment(value: SummaryMode.type, label: Text("Type")),
        ButtonSegment(value: SummaryMode.category, label: Text("Category")),
      ],
      selected: {initValue},
      onSelectionChanged: (selection) {
        onSelect(selection.first);
      },
      showSelectedIcon: false,
    );
  }
}
