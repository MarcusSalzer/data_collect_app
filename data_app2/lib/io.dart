import 'dart:io';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/util/enums.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const eventsCsvHeader = "id, name, start, end";

/// Default Dir for storing exported data.
Future<Directory> defaultUserStoreDir() async {
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

/// Default Dir for storing Internal data (DB, prefs)
Future<Directory> defaultInternalStoreDir() async {
  Directory dir;
  // The applicationDocumentsdirectory is a safe choice, especially for Android.
  // on android the app might not be allowed to write to user facing folders.
  final docDir = await getApplicationDocumentsDirectory();
  if (Platform.isAndroid) {
    // not user accessible, android isolates per app.
    dir = docDir;
  } else {
    // For example on desktop:
    // Pick a sub-dir, to avoid cluttering "Documents"
    dir = Directory(p.join(docDir.path, "data_app_internal"));
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
  final dir = await defaultUserStoreDir();
  final f = File(p.join(dir.path, "app.log"));
  return f;
}

/// Let user pick a single file
Future<String?> pickSingleFile() async {
  final fpRes = await FilePicker.platform.pickFiles(initialDirectory: (await defaultUserStoreDir()).path);
  if (fpRes == null) {
    return null; // canceled
  }
  return fpRes.files.single.path;
}

/// Let user pick a single directory
Future<Directory?> pickSingleFolder() async {
  final path = await FilePicker.platform.getDirectoryPath(initialDirectory: (await defaultUserStoreDir()).path);
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

  EvtImportSummary.fromEvtRecs(Iterable<EvtRec> recs) : mode = ImportMode.event {
    for (final r in recs) {
      final s = r.start?.asUtcWithLocalValue;
      final e = r.end?.asUtcWithLocalValue;
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

  EvtImportSummary.fromEvtDrafts(Iterable<EvtDraft> recs) : mode = ImportMode.event {
    for (final r in recs) {
      final s = r.start?.asUtcWithLocalValue;
      final e = r.end?.asUtcWithLocalValue;
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
