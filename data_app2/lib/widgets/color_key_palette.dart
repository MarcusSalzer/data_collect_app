import 'package:data_app2/util/colors.dart';
import 'package:flutter/material.dart';

class ColorKeyPalette extends StatelessWidget {
  final ColorKey selectedColorKey;
  final ValueChanged<ColorKey> onColorSelected;

  const ColorKeyPalette({
    required this.selectedColorKey,
    required this.onColorSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // You can get the keys to iterate through your defined colors
    final options = ColorKey.values;

    return Scaffold(
      appBar: AppBar(
        title: Text("Color picker"),
      ),
      body: Center(
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options.map((opt) {
            final isSelected = opt == selectedColorKey;
            final color = opt.inContext(context);

            return InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onColorSelected(opt);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onPrimary,
                          width: 3)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
