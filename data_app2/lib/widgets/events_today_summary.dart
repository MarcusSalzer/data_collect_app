// a small widget for seeing todays events

import 'package:data_app2/app_state.dart';
import 'package:data_app2/fmt.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ASCsummary extends StatelessWidget {
  final List<Color> colors = Colors.primaries;
  const ASCsummary({super.key});

  @override
  Widget build(BuildContext context) {
    final thm = Theme.of(context);
    return Consumer<AppState>(
      builder: (context, value, child) {
        final s = value.todaySummary;
        if (s == null) {
          return Text("loading todaySummary");
        }
        if (s.tpe.isEmpty) {
          return const Center(child: Text("No events today"));
        }
        return Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.all(8),
          decoration: ShapeDecoration(
            color: thm.colorScheme.secondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EventDurationTable(tpe: s.tpe, colors: colors),
              HorizontalMultiBar(
                sizes: s.tpe.map((entry) => entry.value.inMinutes),
                colors: colors,
              ),
            ],
          ),
        );
      },
    );
  }
}

class HorizontalMultiBar extends StatelessWidget {
  final Iterable<int> sizes;
  final List<Color> colors;
  const HorizontalMultiBar(
      {super.key, required this.sizes, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 5,
      child: Flex(
        direction: Axis.horizontal,
        children: [
          for (final (i, s) in sizes.indexed)
            Flexible(
              flex: s,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2),
                color: colors[i % colors.length],
              ),
            )
        ],
      ),
    );
  }
}

/// A Table showing events, each with a duration
class EventDurationTable extends StatelessWidget {
  final List<MapEntry<String, Duration>> tpe;
  late final Duration trackedTime;

  late final List<Color>? colors;

  EventDurationTable({super.key, required this.tpe, this.colors}) {
    trackedTime = tpe.fold(Duration.zero, (p, c) => p + c.value);
  }

  @override
  Widget build(BuildContext context) {
    final comps = [];
    for (final (i, entry) in tpe.indexed) {
      comps.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 2,
              child: Text(
                entry.key,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: colors?[i % (colors?.length ?? 1)]),
              ),
            ),
            Flexible(
              flex: 1,
              child: Text(
                durationHM(entry.value),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 2,
                    child: Text(
                      "Tracked time today",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: Text(
                      durationHM(trackedTime),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            ...comps
          ],
        );
      },
    );
  }
}
