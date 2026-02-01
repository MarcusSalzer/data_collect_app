import 'package:data_app2/csv_2/csv_row.dart';
import 'package:data_app2/errors/csv_format_error.dart';

// Maybe idk...
class CsvResult {
  CsvResult(this.errors, this.warnings);
  List<CsvFormatError> errors;
  List<String> warnings;
}

class CsvSchema {
  final List<String> writeCols;
  final Set<String> requiredCols; // Should be a subset of writeCols

  const CsvSchema(this.writeCols, this.requiredCols);
  Set<String> get optionalCols => writeCols.toSet().difference(requiredCols);
}

abstract class CsvCodecWriteOnly<T> {
  // consistent order for writing
  final String sep;
  // Use this for validating header (fail early)
  CsvSchema get schema;
  String get header => schema.writeCols.join(sep);

  CsvCodecWriteOnly({this.sep = ","});
  // use row when writing too
  // allows ensuring the same order as writeCols, and gets the same validation,
  // so, if something cannot be read it cannot be written either
  CsvRow toRow(T d);
}

/// Define how a Data class is converted to and from CSV
abstract class CsvCodecRW<T> extends CsvCodecWriteOnly<T> {
  CsvCodecRW({super.sep = ","});

  // The CsvRow class has opt/req methods for each possible datatype
  // These methods can be used blindly inside build, but will throw errors
  // when data validation fails
  T build(CsvRow r);

  /// TODO: also throw (or at least warn) on unwanted columns?
  void validateHeader(String fileHeader) {
    final fileCols = fileHeader.split(sep);
    final fileSet = fileCols.toSet();
    if (fileSet.length < fileCols.length) {
      throw CsvFormatError(row: 0, message: "Duplicate columns");
    }
    final missing = schema.requiredCols.difference(fileSet);
    if (missing.isNotEmpty) {
      throw CsvFormatError(row: 0, message: "Missing columns: ${missing.join(', ')}");
    }
  }

  /// Will work for any subclass
  String rowToStr(CsvRow r, {String nullValue = ""}) {
    return schema.writeCols
        .map((c) {
          final v = (schema.requiredCols.contains(c) ? r.req(c) : r.opt(c)) ?? nullValue;
          if (v.contains(sep)) {
            throw FormatException("cannot write '$v' (contains csv-separator '$sep')");
          }
          return v;
        })
        .join(sep);
  }

  Iterable<CsvRow> parseRows(Iterable<String> linesWithHeader) sync* {
    final fileCols = linesWithHeader.first.split(sep);

    for (final (i, line) in linesWithHeader.skip(1).indexed) {
      // trim leading/trailing whitespace!
      final values = line.split(sep).map((v) => v.trim());
      try {
        yield CsvRow(Map.fromIterables(fileCols, values));
      } on FormatException catch (e) {
        // Rethrow as a CSV error, with row information
        throw CsvFormatError(row: i, message: e.message);
      }
    }
  }

  /// for converting rows to data objects.
  Iterable<T> decode(Iterable<CsvRow> rows) sync* {
    for (final (i, row) in rows.indexed) {
      try {
        yield build(row);
      } catch (e) {
        throw CsvFormatError(row: i, message: e.toString());
      }
    }
  }

  Iterable<String> encode(Iterable<T> items) {
    return [header].followedBy(items.map((e) => rowToStr(toRow(e))));
  }

  /// not needed?
  Stream<T> decodeAsync(Stream<CsvRow> rows, Future<T> Function(CsvRow) buildAsync) async* {
    var i = 1;
    await for (final row in rows) {
      try {
        yield await buildAsync(row);
      } catch (e) {
        throw CsvFormatError(row: i, message: e.toString());
      }
      i++;
    }
  }
}
