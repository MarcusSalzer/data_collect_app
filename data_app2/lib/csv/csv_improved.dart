import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/errors/csv_format_error.dart';
import 'package:data_app2/event_type_manager.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/util/colors.dart';

typedef CsvColDef = List<String>;

const colsEvt = ["id", "type_name", "start_utc", "start_offset_s", "end_utc", "end_offset_s"];

class CsvRow {
  final Map<String, String> _row;
  final int rowIndex;

  CsvRow(this.rowIndex, this._row);

  String req(String col) {
    final v = _row[col];
    if (v == null) {
      throw CsvFormatError(row: rowIndex, msg: "Missing column '$col'");
    }
    return v;
  }

  // optional
  String? opt(String col) => _row[col];

  /// get both or nothing
  (String, String)? optPair(String col1, String col2) {
    final v1 = _row[col1];
    final v2 = _row[col2];

    if (v1 == null || v2 == null) return null;
    return (v1, v2);
  }

  /// get both or nothing
  (int, int)? optPairInt(String col1, String col2) {
    final p = optPair(col1, col2);
    return (p == null) ? null : (int.parse(p.$1), int.parse(p.$2));
  }

  int? intOpt(String col) {
    final v = _row[col];
    return v == null ? null : int.parse(v);
  }

  int intReq(String col) => int.parse(req(col));
}

class CsvReaderMap {
  final CsvColDef requiredCols;
  final String sep;

  const CsvReaderMap(this.requiredCols, {this.sep = ","});
  Iterable<CsvRow> parseRows(Iterable<String> lines) sync* {
    final it = lines.iterator;
    if (!it.moveNext()) return;

    final fileCols = it.current.split(sep);
    _validateHeader(fileCols);

    var rowIndex = 1;
    while (it.moveNext()) {
      final values = it.current.split(sep);
      yield CsvRow(rowIndex, Map.fromIterables(fileCols, values));
      rowIndex++;
    }
  }

  void _validateHeader(List<String> givenCols) {
    final missing = requiredCols.toSet().difference(givenCols.toSet());
    if (missing.isNotEmpty) {
      throw CsvFormatError(row: 0, msg: "Missing columns: ${missing.join(', ')}");
    }
  }
}

Iterable<T> decode<T>(Iterable<CsvRow> rows, T Function(CsvRow) build) sync* {
  var i = 1;
  for (final row in rows) {
    try {
      yield build(row);
    } catch (e) {
      throw CsvFormatError(row: i, msg: e.toString());
    }
    i++;
  }
}

Stream<T> decodeAsync<T>(Stream<CsvRow> rows, Future<T> Function(CsvRow) build) async* {
  var i = 1;
  await for (final row in rows) {
    try {
      yield await build(row);
    } catch (e) {
      throw CsvFormatError(row: i, msg: e.toString());
    }
    i++;
  }
}

class EvtTypeCsvDecoding {
  /// Decode drafts from CSV
  static Iterable<EvtTypeDraft> decodeDrafts(Iterable<String> lines) {
    final rows = CsvReaderMap(["name"]).parseRows(lines);

    return decode(rows, (r) {
      final cname = r.req("color");
      return EvtTypeDraft(r.req("name"), colorKeysByName[cname] ?? ColorKey.base);
    });
  }

  /// Decode recs from CSV
  static Iterable<EvtTypeRec> decodeRecs(Iterable<String> lines) {
    final rows = CsvReaderMap(["id", "name"]).parseRows(lines);

    return decode(rows, (r) {
      final cname = r.opt("color");
      return EvtTypeRec(r.intReq("id"), r.req("name"), colorKeysByName[cname] ?? ColorKey.base);
    });
  }
}

class EvtCatCsvDecoding {
  /// Decode drafts from CSV
  static Iterable<EvtCatDraft> decodeDrafts(Iterable<String> lines) {
    final rows = CsvReaderMap(["name"]).parseRows(lines);

    return decode(rows, (r) => EvtCatDraft(r.req("name")));
  }

  /// Decode recs from CSV
  static Iterable<EvtCatRec> decodeRecs(Iterable<String> lines) {
    final rows = CsvReaderMap(["id", "name"]).parseRows(lines);

    return decode(rows, (r) => EvtCatRec(r.intReq("id"), r.req("name")));
  }
}

class EvtCsvDecoding {
  /// Parse data for LocalDateTime
  static LocalDateTime? _getLdt((String, String)? p) {
    return (p == null) ? null : LocalDateTime.fromUtcISOAndffset(utcIso: p.$1, offsetMillis: int.parse(p.$2));
  }

  /// Decode drafts from CSV
  static Stream<EvtDraft> decodeDrafts(Iterable<String> lines, EvtTypeManagerPersist evtMan) {
    final rows = CsvReaderMap(["type_name", "start_utc", "start_offset_s", "end_utc", "end_offset_s"]).parseRows(lines);

    return decodeAsync(Stream.fromIterable(rows), (r) async {
      final typeId = await evtMan.resolveOrCreate(name: r.req("type_name"));

      return EvtDraft(
        typeId,
        start: _getLdt(r.optPair("start_utc", "start_offset_s")),
        end: _getLdt(r.optPair("end_utc", "end_offset_s")),
      );
    });
  }

  /// Decode drafts from CSV
  static Stream<EvtRec> decodeRecs(Iterable<String> lines, EvtTypeManagerPersist evtMan) {
    final rows = CsvReaderMap([
      "id",
      "type_name",
      "start_utc",
      "start_offset_s",
      "end_utc",
      "end_offset_s",
    ]).parseRows(lines);

    return decodeAsync(Stream.fromIterable(rows), (r) async {
      final typeId = await evtMan.resolveOrCreate(name: r.req("type_name"));

      return EvtRec(
        r.intReq("id"),
        typeId,
        start: _getLdt(r.optPair("start_utc", "start_offset_s")),
        end: _getLdt(r.optPair("end_utc", "end_offset_s")),
      );
    });
  }
}
