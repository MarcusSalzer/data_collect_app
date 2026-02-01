import 'package:data_app2/errors/csv_format_error.dart';

/// Core functionality for both reading and writing CSV.
@Deprecated("use map pipeline instead")
mixin CsvSchemaOld {
  List<String> get cols;
  String get sep => ",";

  String get header => cols.join(sep);
}

/// Core functionality for writing CSV.
@Deprecated("use map pipeline instead")
mixin CsvWriter<T> on CsvSchemaOld {
  String toRow(T rec);

  Iterable<String> encodeRows(Iterable<T> records) => records.map(toRow);

  Iterable<String> encodeRowsWithHeader(Iterable<T> records) => [header].followedBy(encodeRows(records));
}

/// Core functionality for reading CSV.
@Deprecated("use map pipeline instead")
mixin CsvReader<T> on CsvSchemaOld {
  T fromRow(String row);

  T _parseRow(int i, String r) {
    try {
      return fromRow(r);
    } on FormatException catch (e) {
      throw CsvFormatError(row: i, message: e.message);
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
@Deprecated("use map pipeline instead")
abstract class CsvAdapter<T> with CsvSchemaOld, CsvReader<T>, CsvWriter<T> {
  const CsvAdapter();
}
