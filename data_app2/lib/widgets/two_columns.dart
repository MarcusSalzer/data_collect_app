import 'package:flutter/material.dart';

class TwoColumns extends StatelessWidget {
  final (int, int) flex;
  final double spacing;

  final List<(Widget, Widget)> rows;

  const TwoColumns(
      {this.flex = (1, 3), this.spacing = 12, required this.rows, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: spacing,
      children: rows
          .map((pair) => Row(
                children: [
                  Expanded(
                    flex: flex.$1,
                    child: pair.$1,
                  ),
                  Expanded(
                    flex: flex.$2,
                    child: pair.$2,
                  ),
                ],
              ))
          .toList(),
    );
  }
}
