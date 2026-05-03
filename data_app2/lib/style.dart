// Default style for app??

import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';

const filePathText = TextStyle(fontFamily: "monospace");

/// App look
enum ColorSchemeMode {
  light,
  dark,
  black;

  String get label => name.capitalized;

  String get description => switch (this) {
    light => "Classic light theme.",
    dark => "Classic dark theme.",
    black => "Completely black background.",
  };

  ThemeData get theme => switch (this) {
    ColorSchemeMode.light => AppThemes.light,
    ColorSchemeMode.dark => AppThemes.dark,
    ColorSchemeMode.black => AppThemes.black,
  };
}

/// Contains the actual theme data, that can be selected by the color scheme preference
class AppThemes {
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
    useMaterial3: true,
  );

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      primaryContainer: const Color.fromARGB(255, 20, 32, 42),
    ),
    useMaterial3: true,
  );

  static final ThemeData black = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      surface: Colors.black,
      onSurface: Color(0xFFE2E2E2),
      brightness: Brightness.dark,
      inversePrimary: Color.fromARGB(255, 20, 19, 20),
      primaryContainer: Color.fromARGB(255, 8, 8, 8),
      onPrimaryContainer: Color(0xFFD0CDCD),
      secondaryContainer: Color(0xFF242424),
      onSecondaryContainer: Color(0xFFE8E4E4),
    ),
    useMaterial3: true,
  );
}
