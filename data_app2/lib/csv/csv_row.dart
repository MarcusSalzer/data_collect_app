const colsEvt = ["id", "type_name", "start_utc", "start_offset_s", "end_utc", "end_offset_s"];

class CsvRow {
  final Map<String, String?> _row;

  CsvRow(this._row);

  /// Get a string value or throw [FormatException]
  String req(String col) {
    final v = opt(col);
    if (v == null) {
      throw FormatException("Missing column '$col'");
    }
    return v;
  }

  /// Get a string value or throw [FormatException] (parse or missing)
  int reqInt(String col) => int.parse(req(col));

  /// optional string value
  String? opt(String col) {
    final v = _row[col];
    // replace empty with null
    return (v == null || v.isEmpty) ? null : v;
  }

  /// optional int value
  int? optInt(String col) {
    final v = opt(col);
    return (v == null) ? null : int.parse(v);
  }

  /// get both or nothing
  (String, String)? optPair(String col1, String col2) {
    final v1 = _row[col1];
    final v2 = _row[col2];

    if (v1 == null || v2 == null) return null;
    return (v1, v2);
  }

  /// get both or nothing (ints)
  (int, int)? optPairInt(String col1, String col2) {
    final p = optPair(col1, col2);
    return (p == null) ? null : (int.parse(p.$1), int.parse(p.$2));
  }
}

// class CsvReaderMap {
//   final Set<String> requiredCols;
//   final String sep;

//   const CsvReaderMap(this.requiredCols, {this.sep = ","});

//   void _validateHeader(List<String> givenCols) {
//     final givenSet = givenCols.toSet();
//     if (givenSet.length < givenCols.length) {
//       throw CsvFormatError(row: 0, message: "Duplicate columns");
//     }
//     final missing = requiredCols.difference(givenSet);
//     if (missing.isNotEmpty) {
//       throw CsvFormatError(row: 0, message: "Missing columns: ${missing.join(', ')}");
//     }
//   }
// }
