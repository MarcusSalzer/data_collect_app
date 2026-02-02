import 'dart:convert';
import 'dart:io';
import 'package:data_app2/csv_2/builtin_schemas.dart';
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

/// Infer type based on having all "requiredCols"
@Deprecated("unstable...")
ImportFileRole roleFromCols(Set<String> fileCols) {
  final possible = <ImportFileRole>{};

  if (CsvSchemasConst.evtCat.requiredCols.difference(fileCols).isEmpty) {
    possible.add(ImportFileRole.events);
  } else if (CsvSchemasConst.evtType.requiredCols.difference(fileCols).isEmpty) {
    possible.add(ImportFileRole.eventTypes);
  } else if (CsvSchemasConst.evtCat.requiredCols.difference(fileCols).isEmpty) {
    possible.add(ImportFileRole.eventCats);
  }

  if (possible.length == 1) {
    return possible.first;
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
