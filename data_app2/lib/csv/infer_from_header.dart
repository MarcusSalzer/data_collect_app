import 'dart:convert';
import 'dart:io';
import 'package:data_app2/csv_2/builtin_schemas.dart';
import 'package:data_app2/util/enums.dart';
import 'package:flutter/foundation.dart';

/// Infer type based on having all "writeCols"
ImportFileRole roleFromCols(Set<String> fileCols) {
  if (setEquals(fileCols, CsvSchemasConst.evt.writeCols.toSet())) {
    return ImportFileRole.events;
  } else if (setEquals(fileCols, CsvSchemasConst.evtType.writeCols.toSet())) {
    return ImportFileRole.eventTypes;
  } else if (setEquals(fileCols, CsvSchemasConst.evtCat.writeCols.toSet())) {
    return ImportFileRole.eventCats;
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
