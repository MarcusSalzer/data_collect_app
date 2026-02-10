import 'package:data_app2/util/colors.dart';
import 'package:flutter/material.dart';

/// A simple widget to select a color from [ColorEngine.defaults].
class ColorDefaultsPalette extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onColorSelected;

  const ColorDefaultsPalette({required this.selected, required this.onColorSelected, super.key});

  @override
  Widget build(BuildContext context) {
    final options = ColorEngine.defaults.values.toList();
    return Scaffold(
      appBar: AppBar(title: Text("Color picker")),
      body: Center(
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options.map((opt) {
            final isSelected = opt == selected;

            return InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onColorSelected(opt);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: opt,
                  border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onPrimary, width: 3) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
