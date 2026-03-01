// a small widget for seeing todays events

import 'dart:math';
import 'package:data_app2/data/today_summary_data.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:flutter/material.dart';

class MultiBar extends StatelessWidget {
  final Iterable<int> sizes;
  final List<Color> colors;
  final Axis direction;
  final double thickness;
  const MultiBar({
    required this.sizes,
    required this.colors,
    this.direction = Axis.horizontal,
    this.thickness = 5,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: direction == Axis.horizontal ? thickness : null,
      width: direction == Axis.vertical ? thickness : null,
      child: Flex(
        direction: direction,
        children: [
          for (final (i, s) in sizes.indexed)
            Flexible(
              flex: s,
              child: Container(
                // margin: EdgeInsets.symmetric(horizontal: 2),
                color: colors[i % colors.length],
              ),
            ),
        ],
      ),
    );
  }
}

/// A Table showing events, each with a duration
class EventDurationTable extends StatelessWidget {
  final DurationSummaryList summary;

  final Widget title;

  final bool includeBar;

  final double height;

  const EventDurationTable(this.summary, this.title, {super.key, this.includeBar = false, this.height = 220});

  @override
  Widget build(BuildContext context) {
    final comps = <Widget>[];
    for (final entry in summary.items) {
      comps.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Row(
                  spacing: 4,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: entry.color),

                    Text(entry.name, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: Text(
                  Fmt.durationHmVerbose(entry.duration),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final div = includeBar
        ? MultiBar(
            sizes: summary.items.map((entry) => entry.duration.inMinutes),
            colors: summary.items.map((entry) => entry.color).toList(),
            thickness: 5,
          )
        : Divider(color: Theme.of(context).colorScheme.onPrimaryContainer);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(flex: 2, child: title),
              Flexible(
                flex: 1,
                child: Text(
                  Fmt.durationHmVerbose(summary.trackedTime),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        div,
        // Table rows
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            height: min(height, 30.0 * comps.length),
            child: ListView(itemExtent: 30, children: comps),
          ),
        ),
      ],
    );
  }
}
