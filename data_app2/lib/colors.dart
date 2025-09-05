import 'package:flutter/material.dart';

enum ColorKey {
  // item 0: default/base color
  base(light: Colors.grey, dark: Color(0xFFAAAAAA)),
  // Nice colors
  red(
    light: Colors.red,
    dark: Color.fromARGB(255, 255, 83, 83),
  ),
  green(
    light: Colors.green,
    dark: Color(0xFF66FF88),
  ),
  blue(
    light: Colors.blue,
    dark: Color(0xFF42A5FF),
  ),
  amber(
    light: Colors.amber,
    dark: Color(0xFFFFCABB),
  ),
  orange(
    light: Colors.orange,
    dark: Color(0xFFFFDA90),
  );

  final Color light;
  final Color dark;

  const ColorKey({required this.light, required this.dark});

  // color based on the current theme
  Color inContext(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
