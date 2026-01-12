import 'dart:io';
import 'package:data_app2/csv/infer_from_header.dart';
import 'package:data_app2/data/evt_draft.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/util/enums.dart';

/// All importable files
class ImportCandidateCollection {
  List<CsvImportCandidate<EvtDraft>> evtCands = [];
  List<CsvImportCandidate<EvtTypeRec>> evtTypeCands = [];
  List<CsvImportCandidate<Null>> unknownCands = [];

  void clear() {
    evtCands.clear();
    evtTypeCands.clear();
    unknownCands.clear();
  }

  Future<void> addFile(File file) async {
    final cols = await getCsvHeaderCols(file);
    final role = roleFromCols(cols);
    final size = (await file.stat()).size;
    switch (role) {
      case ImportFileRole.events:
        evtCands.add(CsvImportCandidate<EvtDraft>(file, cols, size));
        break;
      case ImportFileRole.eventTypes:
        evtTypeCands.add(CsvImportCandidate<EvtTypeRec>(file, cols, size));
        break;
      case ImportFileRole.unknown:
        unknownCands.add(CsvImportCandidate<Null>(file, cols, size));
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
  final Set<String> cols;
  final int size;
  String? error;

  // load later
  ImportCandidateSummary<T>? summary;

  String get name => file.path.split("/").last;

  CsvImportCandidate(this.file, this.cols, this.size);
}

class ImportCandidateSummary<T> {
  final int count;
  final int idOverlapCount;
  DateTime? earliest;
  DateTime? latest;

  List<T> records;

  ImportCandidateSummary(this.records, this.idOverlapCount)
    : count = records.length {
    // Timestamped?
    if (records case List<EvtDraft> evts) {
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
