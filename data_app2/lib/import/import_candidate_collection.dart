import 'dart:io';
import 'package:data_app2/csv/infer_from_header.dart';
import 'package:data_app2/csv_2/builtin_schemas.dart';
import 'package:data_app2/csv_2/csv_schema.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/util/enums.dart';
import 'package:path/path.dart' as p;

/// All importable files
class ImportCandidateCollection {
  List<CsvImportCandidate<EvtDraft>> evtCands = [];
  List<CsvImportCandidate<EvtTypeDraft>> evtTypeCands = [];
  List<CsvImportCandidate<EvtCatDraft>> evtCatCands = [];
  List<CsvImportCandidate<Null>> unknownCands = [];

  void clear() {
    evtCands.clear();
    evtTypeCands.clear();
    unknownCands.clear();
  }

  Future<void> addFile(File file) async {
    final cols = await getCsvHeaderCols(file);
    final role = roleFromName(p.basename(file.path));
    final size = (await file.stat()).size;
    switch (role) {
      case ImportFileRole.events:
        evtCands.add(CsvImportCandidate<EvtDraft>(file, cols, size, CsvSchemasConst.evt));
        break;
      case ImportFileRole.eventTypes:
        evtTypeCands.add(CsvImportCandidate<EvtTypeDraft>(file, cols, size, CsvSchemasConst.evtType));
        break;
      case ImportFileRole.eventCats:
        evtCatCands.add(CsvImportCandidate<EvtCatDraft>(file, cols, size, CsvSchemasConst.evtCat));
        break;
      case ImportFileRole.unknown:
        unknownCands.add(CsvImportCandidate<Null>(file, cols, size, null));
        break;
    }
  }

  /// can anything be imported
  bool get canImport => evtCands.isNotEmpty || evtTypeCands.isNotEmpty;

  @override
  String toString() {
    return "evt:$evtCands, type:$evtTypeCands, unk:$unknownCands";
  }
}

/// One file that can be imported
class CsvImportCandidate<T> {
  final File file;
  final CsvSchema? schema;
  final Set<String> cols;
  final int size;
  String? error;

  String get name => file.path.split("/").last;

  CsvImportCandidate(this.file, this.cols, this.size, this.schema);

  bool colUsable(String col) {
    return (schema?.writeCols.contains(col) ?? false);
  }
}

class ImportCandidateSummary<T> {
  final int count;
  final int? idOverlapCount;
  DateTime? earliest;
  DateTime? latest;

  List<T> items;

  ImportCandidateSummary(this.items, this.idOverlapCount) : count = items.length {
    // Timestamped?
    if (items case List<EvtRec> evts) {
      // counts first and last
      for (final r in evts) {
        final s = r.start?.asLocal;
        final e = r.end?.asLocal;
        if (s != null) {
          if (earliest == null || s.isBefore(earliest!)) {
            earliest = s;
          }
        }
        if (e != null) {
          if (latest == null || e.isAfter(latest!)) {
            latest = s;
          }
        }
      }
    }
  }
}
