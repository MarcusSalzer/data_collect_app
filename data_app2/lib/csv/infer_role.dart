import 'dart:convert';
import 'dart:io';
import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/util/enums.dart';

/// Choose import mode based on typical file name
ImportFileRole roleFromFileName(String filename) {
  if (filename.contains("events")) {
    return ImportFileRole.events;
  } else if (filename.contains("event_types")) {
    return ImportFileRole.eventTypes;
  } else if (filename.contains("event_categories")) {
    return ImportFileRole.eventCats;
  } else if (filename.contains("locations")) {
    return ImportFileRole.locations;
  } else if (filename == "prefs.json") {
    return ImportFileRole.prefs;
  } else if ({"blob_schemas.ndjson", "blob_schemas.jsonl"}.contains(filename)) {
    return ImportFileRole.blobSchemas;
  } else if ({"blob_records.ndjson", "blob_records.jsonl"}.contains(filename)) {
    return ImportFileRole.blobs;
  }
  return ImportFileRole.unknown;
}

/// Heuristic inference of import role based on having all "requiredCols"
/// If multiple possible, pick the option with fewest useless columns
@Deprecated("Unreliable")
ImportFileRole roleFromCols(Set<String> fileCols) {
  final possibleExcess = <ImportFileRole, int>{};

  for (var MapEntry(key: role, value: sch) in CsvSchemasConst.byImportRoleHuman.entries) {
    if (sch.requiredCols.difference(fileCols).isEmpty) {
      // How many extra columns?
      possibleExcess[role] = fileCols.difference(sch.writeCols.toSet()).length;
    }
  }

  if (possibleExcess.isNotEmpty) {
    final possible = possibleExcess.entries.toList();
    possible.sort((a, b) => a.value.compareTo(b.value));
    return possible.first.key;
  }

  return ImportFileRole.unknown;
}

/// Read a single line from the file
Future<String> _readFirstLine(File file) async {
  // Stream and take first line, will unsubscribe and close automatically
  return file.openRead().transform(utf8.decoder).transform(LineSplitter()).first;
}

Set<String> _parseHeader(String line) {
  return line.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
}

Future<Set<String>> getCsvHeaderCols(File file) async {
  final line = await _readFirstLine(file);
  return _parseHeader(line);
}
