import 'package:flutter/material.dart';

enum ColorKey {
  // item 0: default/base color
  base(light: Colors.grey, dark: Color(0xFFAAAAAA)),
  // Nice colors
  red(light: Colors.red, dark: Color.fromARGB(255, 255, 83, 83)),
  green(light: Colors.green, dark: Color(0xFF66FF88)),
  blue(light: Colors.blue, dark: Color(0xFF42A5FF)),
  amber(light: Colors.amber, dark: Color(0xFFFFCABB)),
  orange(light: Colors.orange, dark: Color(0xFFFFDA90)),
  cyan(light: Colors.cyan, dark: Color.fromARGB(255, 150, 212, 223)),
  purple(light: Colors.purple, dark: Color.fromARGB(255, 180, 67, 200));

  final Color light;
  final Color dark;

  const ColorKey({required this.light, required this.dark});

  // color based on the current theme
  Color inContext(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}

/// Allow nicely distributed groups of colors
class ComputedColors {
  static const nBaseHues = 9;

  List<HSLColor> baseHues() {
    const dStep = 360 / nBaseHues;
    return List.generate(
      nBaseHues,
      (i) => HSLColor.fromAHSL(1.0, i * dStep, 0.7, 0.5),
    );
  }

  const ComputedColors();
}
