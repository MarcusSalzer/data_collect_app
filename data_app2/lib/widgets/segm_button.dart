import 'package:data_app2/util/enums.dart';
import 'package:data_app2/widgets/reusable_icons.dart';
import 'package:flutter/material.dart';

/// Segmented button for selecting between a few options
class GenericSegmButton<T> extends StatelessWidget {
  final T initValue;
  final void Function(T) onSelect;
  final List<(T, Widget)> items;

  const GenericSegmButton(this.initValue, this.onSelect, this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      style: SegmentedButton.styleFrom(side: BorderSide(color: const Color.fromARGB(0, 47, 47, 47))),
      segments: items.map((i) => ButtonSegment(value: i.$1, label: i.$2)).toList(),
      selected: {initValue},
      onSelectionChanged: (selection) {
        onSelect(selection.first);
      },
      showSelectedIcon: false,
    );
  }
}

/// commonly used segmbutton for selecting sumamry mode
class SummaryModeSegmButton extends GenericSegmButton<SummaryMode> {
  const SummaryModeSegmButton(SummaryMode initValue, void Function(SummaryMode) onSelect, {super.key})
    : super(initValue, onSelect, const [
        (SummaryMode.type, evtTypeIcon),
        (SummaryMode.category, evtCatIcon),
      ]);
}
