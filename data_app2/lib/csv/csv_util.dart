import 'package:data_app2/errors/csv_format_error.dart';

/// Core functionality for both reading and writing CSV.
mixin CsvSchema {
  List<String> get cols;
  String get sep => ",";

  String get header => cols.join(sep);
}

/// Core functionality for writing CSV.
mixin CsvWriter<T> on CsvSchema {
  String toRow(T rec);

  Iterable<String> encodeRows(Iterable<T> records) => records.map(toRow);

  Iterable<String> encodeRowsWithHeader(Iterable<T> records) =>
      [header].followedBy(encodeRows(records));
}

/// Core functionality for reading CSV.
mixin CsvReader<T> on CsvSchema {
  T fromRow(String row);

  T _parseRow(int i, String r) {
    try {
      return fromRow(r);
    } on FormatException catch (e) {
      throw CsvFormatError(row: i, msg: e.message);
    }
  }

  List<T> parseRows(Iterable<String> rows) {
    final recs = <T>[];
    for (var (i, r) in rows.indexed) {
      recs.add(_parseRow(i, r));
    }
    return recs;
  }
}

/// For round-trip data
abstract class CsvAdapter<T> with CsvSchema, CsvReader<T>, CsvWriter<T> {
  const CsvAdapter();
}
