import 'dart:convert';
import 'dart:io';

import 'package:data_app2/csv/evt_csv_adapter.dart';
import 'package:data_app2/csv/evt_type_csv_adapter.dart';
import 'package:data_app2/util/enums.dart';
import 'package:flutter/foundation.dart';

ImportFileRole roleFromCols(Set<String> fileCols) {
  if (setEquals(fileCols, EvtCsvAdapter().cols.toSet())) {
    return ImportFileRole.events;
  } else if (setEquals(fileCols, EvtTypeCsvAdapter().cols.toSet())) {
    return ImportFileRole.eventTypes;
  }
  return ImportFileRole.unknown;
}

/// Read a single line from the file
Future<String> _readFirstLine(File file) async {
  return file
      .openRead()
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .first;
}

Set<String> _parseHeader(String line) {
  return line
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();
}

Future<Set<String>> getCsvHeaderCols(File file) async {
  final line = await _readFirstLine(file);
  return _parseHeader(line);
}
