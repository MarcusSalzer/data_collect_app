import 'dart:io';

import 'package:data_app2/csv/csv_simple.dart';
import 'package:data_app2/db_service.dart' show Event;
import 'package:data_app2/enums.dart';
import 'package:data_app2/extensions.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/user_tabular.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const eventsCsvHeader = "id, name, start, end";

/// Export events as CSV
Future<int> exportEvents(
    Iterable<Event> events, Map<int, String> idToName) async {
  final nEvt = events.length;
  final lines = events.map((evt) {
    final name = idToName[evt.typeId];
    if (name == null) {
      throw Exception("not in map");
    }
    final nameSafe = name.replaceAll(",", ";");

    return "${evt.id}, $nameSafe, ${evt.startUtcMillis}, ${evt.startLocalMillis}, ${evt.startLocalMillis}, ${evt.endLocalMillis}";
  });
  final csvContent = "$eventsCsvHeader\n${lines.join('\n')}";

  final fileName = 'events_${Fmt.dtSecond(DateTime.now())}.csv';
  exportFile(fileName, csvContent);
  return nEvt;
}

/// DEPRECATED Import events from a CSV
///
/// considers full file with header
/// Throws [FormatException] if CSV has unexpected header
Future<Iterable<List<String>>> readEventsCSV(String path) async {
  final file = File(path);

  final lines = await file.readAsLines();
  // compare header without spaces
  if (lines[0].equalsIgnoreSpace(eventsCsvHeader)) {
    throw FormatException("wrong CSV header: ${lines[0]}");
  }

  // return parseCSV(lines.skip(1), EvtRec.fromRow);

  final splitted = lines.map((line) => line.split(", "));
  return splitted;
}

/// Parse each row with a function
// Iterable<T> parseCSV<T>(
//   Iterable<String> lines,
//   T Function(List<String>) fromRow,
// ) sync* {
//   for (final li in lines) {
//     yield fromRow(li.split(","));
//   }
// }

/// Pick a user-accessible directory on Android
Future<Directory> defaultStoreDir() async {
  if (Platform.isAndroid) {
    return Directory('/storage/emulated/0/Documents/data_app');
  } else {
    final docDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(docDir.path, "data_app"));
  }
}

/// export records as csv
String tableRecordsToCsv(Iterable<TableRecord> recs, String header) {
  final rows = recs.map((r) => r.toCsvRow()).join("\n");
  return "$header\n$rows";
}

/// Write a [String] of content to a file in the storage folder
Future<void> exportFile(String name, String content) async {
  // throw Deprecated("message");
  // final dir = await defaultStoreDir();
  // if (!dir.existsSync()) {
  //   dir.createSync(recursive: true);
  // }
  // final file = File(
  //   p.join(dir.path, name),
  // );
  // file.writeAsString(content);
}

/// Let user pick a single file
Future<String?> pickSingleFile() async {
  final fpRes = await FilePicker.platform
      .pickFiles(initialDirectory: (await defaultStoreDir()).path);
  if (fpRes == null) {
    return null; // canceled
  }
  return fpRes.files.single.path;
}

/// Check what data is loaded for import
class ImportableSummary {
  int count = 0;
  int nullCount = 0;

  DateTime? earliest;
  DateTime? latest;
  ImportMode mode;
  int? idOverlapCount;

  ImportableSummary.fromEvtRecs(Iterable<EvtRec> recs)
      : mode = ImportMode.event {
    for (final r in recs) {
      final s = r.start?.asLocal;
      final e = r.end?.asLocal;
      if (s != null) {
        if (earliest == null || s.isBefore(earliest!)) {
          earliest = s;
        }
      } else {
        nullCount++;
      }
      if (e != null) {
        if (latest == null || e.isAfter(latest!)) {
          latest = s;
        }
      } else {
        nullCount++;
      }
      count++;
    }
  }

  ImportableSummary.fromEvtDrafts(Iterable<EvtDraft> recs)
      : mode = ImportMode.event {
    for (final r in recs) {
      final s = r.start?.asLocal;
      final e = r.end?.asLocal;
      if (s != null) {
        if (earliest == null || s.isBefore(earliest!)) {
          earliest = s;
        }
      } else {
        nullCount++;
      }
      if (e != null) {
        if (latest == null || e.isAfter(latest!)) {
          latest = s;
        }
      } else {
        nullCount++;
      }
      count++;
    }
  }
}
