import 'package:data_app2/isar_models.dart';
import 'package:data_app2/style.dart';
import 'package:data_app2/util/enums.dart';

/// Represent preferences in memory.
/// Immutable for consistent updates.
class AppPrefs {
  final ColorSchemeMode colorSchemeMode;
  final LogLevel logLevel;
  final bool autoLowerCase;
  final TextSearchMode textSearchMode;

  /// with defaults
  const AppPrefs({
    this.colorSchemeMode = ColorSchemeMode.dark,
    this.logLevel = LogLevel.debug,
    this.autoLowerCase = false,
    this.textSearchMode = TextSearchMode.starts,
  });

  AppPrefs copyWith({
    ColorSchemeMode? colorSchemeMode,
    LogLevel? logLevel,
    bool? autoLowerCase,
    TextSearchMode? textSearchMode,
  }) {
    return AppPrefs(
      colorSchemeMode: colorSchemeMode ?? this.colorSchemeMode,
      logLevel: logLevel ?? this.logLevel,
      autoLowerCase: autoLowerCase ?? this.autoLowerCase,
      textSearchMode: textSearchMode ?? this.textSearchMode,
    );
  }

  factory AppPrefs.fromIsar(Preferences? prefs) {
    if (prefs == null) {
      // default
      return AppPrefs();
    }
    return AppPrefs(
      colorSchemeMode: prefs.colorSchemeMode,
      logLevel: prefs.logLevel,
      autoLowerCase: prefs.autoLowerCase,
      textSearchMode: prefs.textSearchMode,
    );
  }

  Preferences toIsar() {
    return Preferences(colorSchemeMode, autoLowerCase, logLevel, textSearchMode);
  }
}
