import 'dart:convert';
import 'dart:io';
import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/util/enums.dart';

ImportFileRole roleFromName(String filename) {
  if (filename.contains("events")) {
    return ImportFileRole.events;
  } else if (filename.contains("event_types")) {
    return ImportFileRole.eventTypes;
  } else if (filename.contains("event_categories")) {
    return ImportFileRole.eventCats;
  }
  return ImportFileRole.unknown;
}

/// Heuristic inference of import role based on having all "requiredCols"
/// If multiple possible, pick the option with fewest useless columns
@Deprecated("Unreliable")
ImportFileRole roleFromCols(Set<String> fileCols) {
  final possibleExcess = <ImportFileRole, int>{};

  for (var MapEntry(key: role, value: sch) in CsvSchemasConst.byImportRole.entries) {
    if (sch.requiredCols.difference(fileCols).isEmpty) {
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
  return file.openRead().transform(utf8.decoder).transform(LineSplitter()).first;
}

Set<String> _parseHeader(String line) {
  return line.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
}

Future<Set<String>> getCsvHeaderCols(File file) async {
  final line = await _readFirstLine(file);
  return _parseHeader(line);
}
