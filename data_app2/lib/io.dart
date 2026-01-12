import 'dart:io';

import 'package:data_app2/data/evt_draft.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/user_events.dart';
import 'package:data_app2/user_tabular.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const eventsCsvHeader = "id, name, start, end";

/// Default Dir for storing exported data.
Future<Directory> defaultStoreDir() async {
  Directory dir;
  if (Platform.isAndroid) {
    // Pick a user-accessible directory on Android
    dir = Directory('/storage/emulated/0/Documents/data_app');
  } else {
    final docDir = await getApplicationDocumentsDirectory();
    dir = Directory(p.join(docDir.path, "data_app"));
  }
  if (!(await dir.exists())) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Get temporary storage
/// TODO Directory.systemTemp instead?
Future<Directory> defaultTmpDir() async {
  Directory dir;

  try {
    dir = await getApplicationCacheDirectory();
  } on MissingPluginException catch (e) {
    dir = Directory("/tmp/data_app_cache/");
    Logger.root.warning(e);
  } on MissingPlatformDirectoryException catch (e) {
    dir = Directory("/tmp/data_app_cache/");
    Logger.root.warning(e);
  }
  // make sure exists
  await dir.create(recursive: true);
  return dir;
}

/// Default file for logging
Future<File> defaultLogFile() async {
  final dir = await defaultStoreDir();
  final f = File(p.join(dir.path, "app.log"));
  return f;
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
  final fpRes = await FilePicker.platform.pickFiles(
    initialDirectory: (await defaultStoreDir()).path,
  );
  if (fpRes == null) {
    return null; // canceled
  }
  return fpRes.files.single.path;
}

/// Let user pick a single directory
Future<Directory?> pickSingleFolder() async {
  final path = await FilePicker.platform.getDirectoryPath(
    initialDirectory: (await defaultStoreDir()).path,
  );
  return path != null ? Directory(path) : null;
}

/// Check what data is loaded for import
class EvtImportSummary {
  int count = 0;
  int nullCount = 0;

  DateTime? earliest;
  DateTime? latest;
  ImportMode mode;
  int? idOverlapCount;

  EvtImportSummary.fromEvtRecs(Iterable<EvtRec> recs)
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

  EvtImportSummary.fromEvtDrafts(Iterable<EvtDraft> recs)
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
