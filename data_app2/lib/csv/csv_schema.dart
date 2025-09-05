import 'package:data_app2/extensions.dart';

const separators = [",", ";", "\t"];

enum SchemaLevel {
  /// just the needed internal representation (integers)
  raw("Matches internal database"),

  /// more readable (dates as strings etc)
  human("More readable");

  final String desc;
  const SchemaLevel(this.desc);
}

enum RecordKind { event, eventType }

sealed class CsvSchemaDetectionResult {}

class CsvSchemaFound extends CsvSchemaDetectionResult {
  String sep;
  RecordKind kind;
  SchemaLevel schemaLevel;
  CsvSchemaFound(this.sep, this.kind, this.schemaLevel);
  @override
  String toString() {
    return "SchemaFound($sep, $kind, $schemaLevel)";
  }
}

class CsvSchemaNotFound extends CsvSchemaDetectionResult {
  List<String> missing;
  CsvSchemaNotFound(this.missing);
}

class SchemaRegistry {
  static final Map<(RecordKind, SchemaLevel), List<String>> _schemas = {
    // EVENTS
    (RecordKind.event, SchemaLevel.raw): [
      "id",
      "type_id",
      "start_utc_ms",
      "start_local_ms",
      "end_utc_ms",
      "end_local_ms",
    ],
    (RecordKind.event, SchemaLevel.human): [
      "id",
      "type_name",
      "start_utc_dt",
      "start_local_dt",
      "end_utc_dt",
      "end_local_dt",
    ],
    (RecordKind.eventType, SchemaLevel.raw): [
      "id",
      "name",
      "color_id",
      // "cat_id",
    ],
    (RecordKind.eventType, SchemaLevel.human): [
      "id",
      "name",
      "color_name",
      // "cat_?",
    ],
    // EVENT TYPES
  };
  static List<List<String>> allForKinds(List<RecordKind> kinds) {
    return _schemas.entries
        .where((e) => kinds.contains(e.key.$1))
        .map((e) => e.value)
        .toList();
  }

  static List<String> forSchema(RecordKind kind, SchemaLevel level) =>
      _schemas[(kind, level)]!;

  static CsvSchemaFound? inferFromHeaderLine(
    String header,
    RecordKind kind, [
    bool ordered = true,
  ]) {
    for (var sep in separators) {
      // split header and trim each item
      // final words = header.split(sep).map((w) => w.trim());
      for (var lev in SchemaLevel.values) {
        if (ordered) {
          if (SchemaRegistry.forSchema(kind, lev)
              .join(sep)
              .equalsIgnoreSpace(header)) {
            return CsvSchemaFound(sep, kind, lev);
          }
        } else {
          throw UnimplementedError("Permutation parsing not implemented");
          // final expected = Set.of(SchemaRegistry.forSchema(kind, lev));

          // if (expected.difference(Set.of(words)).isEmpty) {
          // return CsvSchemaFound(sep, kind, lev);
          // }
        }
      }
    }
    return null;
  }
}
