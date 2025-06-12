import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EventPieChart extends StatelessWidget {
  const EventPieChart({
    super.key,
    required this.timings,
    required this.colors,
    this.nTitles = 6,
  });

  final List<MapEntry<String, Duration>> timings;
  final List<MaterialColor> colors;

  final int nTitles;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: PieChart(
        PieChartData(
          sections: [
            for (int i = 0; i < timings.length; i++)
              PieChartSectionData(
                value: max(timings[i].value.inMinutes.toDouble(), 1),
                radius: 100,
                title: i < nTitles ? timings[i].key : "",
                color: timings[i].key == "other"
                    ? Colors.grey
                    : colors[i % colors.length],
              )
          ],
        ),
      ),
    );
  }
}

FlTitlesData minimalTitlesData(String xlabel, String ylabel) {
  return FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      axisNameWidget: Text(xlabel),
      sideTitles: SideTitles(showTitles: true),
    ),
    leftTitles: AxisTitles(
      axisNameWidget: Text(ylabel),
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    rightTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
  );
}
