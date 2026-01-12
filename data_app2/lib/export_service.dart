import 'dart:io';

import 'package:data_app2/csv/csv_util.dart';
import 'package:data_app2/csv/evt_csv_adapter.dart';
import 'package:data_app2/csv/evt_type_csv_adapter.dart';
import 'package:data_app2/data/evt_draft.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:path/path.dart' as p;

/// Handles data export.
///
/// Note that an export is a directory, containing a few csv-files.
class CsvExportService {
  /// Generate name based on UTC timestamp
  static String _genName(DateTime dt) {
    return Fmt.dtSecondSimple(dt.toUtc());
  }

  final String name;
  final Directory parent;

  String get folderPath => p.join(parent.path, name);

  CsvExportService(this.parent, DateTime now) : name = _genName(now);

  /// Export all data
  Future<({int nEvt, int nType})> doExport(
    Iterable<EvtDraft>? evts,
    Iterable<EvtTypeRec>? evtTypes,
  ) async {
    // Count exported records
    var nEvt = 0;
    var nType = 0;

    if (evts != null) {
      nEvt = await _save<EvtDraft>(evts, EvtCsvAdapter(), "events_all.csv");
    }
    if (evtTypes != null) {
      nType = await _save<EvtTypeRec>(
        evtTypes,
        EvtTypeCsvAdapter(),
        "event_types.csv",
      );
    }
    return (nEvt: nEvt, nType: nType);
  }

  /// Save some data with a compatible adapter
  Future<int> _save<T>(
    Iterable<T> records,
    CsvAdapter<T> adapter,
    String filename,
  ) async {
    // prepare file
    final file = File(p.join(folderPath, filename));
    if (await file.exists()) {
      // TODO: Pathexists error?
      throw ExportError("Target (${file.path}) already exists.");
    }
    await file.create(recursive: true);

    // format content
    final lines = adapter.encodeRowsWithHeader(records).toList();
    // write contents
    await file.writeAsString(lines.join("\n"));
    // How many lines were written
    return lines.length;
  }
}

class ExportError implements Exception {
  String msg;
  ExportError(this.msg);

  @override
  String toString() {
    return "Export error: $msg";
  }
}
