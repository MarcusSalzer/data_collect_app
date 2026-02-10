import 'package:data_app2/style.dart';
import 'package:data_app2/util/enums.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_prefs.g.dart';

/// Represent preferences in memory.
/// Immutable for consistent updates.
@JsonSerializable()
class AppPrefs {
  @JsonKey(defaultValue: ColorSchemeMode.dark)
  final ColorSchemeMode colorSchemeMode;

  @JsonKey(defaultValue: LogLevel.warning)
  final LogLevel logLevel;

  @JsonKey(defaultValue: SummaryMode.type)
  final SummaryMode summaryMode;

  @JsonKey(defaultValue: TextSearchMode.starts)
  final TextSearchMode textSearchMode;

  final bool autoLowerCase;

  final double colorSpread;

  const AppPrefs({
    this.colorSchemeMode = ColorSchemeMode.dark,
    this.logLevel = LogLevel.warning,
    this.summaryMode = SummaryMode.type,
    this.autoLowerCase = false,
    this.textSearchMode = TextSearchMode.starts,
    this.colorSpread = 0.5,
  });

  AppPrefs copyWith({
    ColorSchemeMode? colorSchemeMode,
    LogLevel? logLevel,
    SummaryMode? summaryMode,
    bool? autoLowerCase,
    TextSearchMode? textSearchMode,
    double? colorSpread,
  }) {
    return AppPrefs(
      colorSchemeMode: colorSchemeMode ?? this.colorSchemeMode,
      logLevel: logLevel ?? this.logLevel,
      summaryMode: summaryMode ?? this.summaryMode,
      autoLowerCase: autoLowerCase ?? this.autoLowerCase,
      textSearchMode: textSearchMode ?? this.textSearchMode,
      colorSpread: colorSpread ?? this.colorSpread,
    );
  }

  factory AppPrefs.fromJson(Map<String, dynamic> json) => _$AppPrefsFromJson(json);

  Map<String, dynamic> toJson() => _$AppPrefsToJson(this);
}
