// a small widget for seeing todays events

import 'dart:math';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Displays a small summary table, using data in appstate.
class EventsTodaySummaryFromAppState extends StatelessWidget {
  const EventsTodaySummaryFromAppState({super.key});

  @override
  Widget build(BuildContext context) {
    final thm = Theme.of(context);
    return Consumer<AppState>(
      builder: (context, app, child) {
        final summary = app.todaySummary;
        if (summary == null) {
          return Text("loading todaySummary");
        }
        if (summary.tpe.isEmpty) {
          return const Center(child: Text("No events today"));
        }
        return Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.all(8),
          decoration: ShapeDecoration(
            color: thm.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(1)),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EventDurationTable(tpe: summary.tpe),
              SizedBox(height: 10),
              MultiBar.horizontal(
                sizes: summary.tpe.map((entry) => entry.value.inMinutes),
                colors: summary.tpe
                    .map((entry) => entry.key.color.inContext(context))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MultiBar extends StatelessWidget {
  final Iterable<int> sizes;
  final List<Color> colors;
  final Axis direction;
  final double thickness;

  // horizontal
  const MultiBar.horizontal({
    super.key,
    required this.sizes,
    required this.colors,
    this.thickness = 5,
  }) : direction = Axis.horizontal;
  // vertical
  const MultiBar.vertical({
    super.key,
    required this.sizes,
    required this.colors,
    this.thickness = 5,
  }) : direction = Axis.horizontal;

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
  final List<MapEntry<EvtTypeRec, Duration>> tpe;
  late final Duration trackedTime;

  final String title;

  final bool includeBar;

  final double height;

  EventDurationTable({
    super.key,
    required this.tpe,
    this.title = "Tracked time today",
    this.includeBar = false,
    this.height = 220,
  }) {
    trackedTime = tpe.fold(Duration.zero, (p, c) => p + c.value);
  }

  @override
  Widget build(BuildContext context) {
    final comps = <Widget>[];
    for (final entry in tpe) {
      comps.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Row(
                  spacing: 4,
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: entry.key.color.inContext(context),
                    ),

                    Text(entry.key.name, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: Text(
                  Fmt.durationHmVerbose(entry.value),
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
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: MultiBar.horizontal(
              sizes: tpe.map((entry) => entry.value.inMinutes),
              colors: tpe
                  .map((entry) => entry.key.color.inContext(context))
                  .toList(),
              thickness: 3,
            ),
          )
        : Divider(color: Theme.of(context).colorScheme.onPrimaryContainer);

    return Column(
      // mainAxisSize: MainAxisSize.min,
      children: [
        // TITLE ROW
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                flex: 1,
                child: Text(
                  Fmt.durationHmVerbose(trackedTime),
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
        div,
        // Table rows
        SizedBox(
          height: min(height, 30.0 * comps.length),
          child: ListView(itemExtent: 30, children: comps),
        ),
      ],
    );
  }
}

class EventsSummary extends StatelessWidget {
  const EventsSummary({
    super.key,
    required this.title,
    required this.tpe,
    this.listHeight = 220,
  });

  final String title;

  final List<MapEntry<EvtTypeRec, Duration>> tpe;

  final double listHeight;

  @override
  Widget build(BuildContext context) {
    final thm = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(8),
      decoration: ShapeDecoration(
        color: thm.colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(1)),
        ),
      ),
      child: EventDurationTable(
        tpe: tpe,
        title: title,
        includeBar: true,
        height: listHeight,
      ),
    );
  }
}
