import 'dart:convert';
import 'dart:io';

import 'package:data_app2/csv/infer_role.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/import_registry.dart';
import 'package:data_app2/importv2.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';

const extensionsSupport = {
  "csv": ImportFileExtension.csv,
  "json": ImportFileExtension.json,
  // two typical extensions for ndjson
  "ndjson": ImportFileExtension.ndjson,
  "jsonl": ImportFileExtension.ndjson,
};

/// Get the fields from csv header or (top-level) json keys
Future<(Set<String>, int)> parseFieldsAndCount(File file, ImportFileExtension extension) async {
  switch (extension) {
    // CSV -> look at header
    case ImportFileExtension.csv:
      return (await getCsvHeaderCols(file), (await countLinesUtf8(file)) - 1);

    // JSON -> Check keys
    case ImportFileExtension.json:
      final obj = jsonDecode(await file.readAsString());

      if (obj is Map<String, Object?>) {
        return (obj.keys.toSet(), 1); // single record
      } else {
        throw FormatException("Only map-json with string keys supported", obj);
      }
    // NDJSON -> Union of keys for all lines
    case ImportFileExtension.ndjson:
      final seen = <String>{};
      var c = 0;
      await for (var line in file.openRead().transform(utf8.decoder).transform(LineSplitter())) {
        final obj = jsonDecode(line);
        c++; // count
        if (obj is Map<String, Object?>) {
          seen.addAll(obj.keys);
        } else {
          throw FormatException("Only map-json with string keys supported", obj);
        }
      }
      return (seen, c);
  }
}

/// Something we might want to import
class RawDataFile {
  final File file;
  final ImportFileRole role;
  final ImportFileExtension extension;
  final int sizeBytes;
  // Parse later
  Set<String>? fields;
  int? nRecords;
  FileImporter? importer;

  Set<String>? get missingFields => importer?.requiredFields.difference(fields ?? {});

  bool get isOk => missingFields?.isEmpty ?? false;

  RawDataFile(
    this.file,
    this.role,
    this.extension,
    this.sizeBytes,
  );
  factory RawDataFile.fromFile(File file, ImportFileExtension ext) =>
      RawDataFile(file, roleFromFileName(file.basename), ext, file.statSync().size);

  @override
  String toString() {
    return "(${file.basename}, $role, ${sizeBytes ~/ 1024} kiB)";
  }
}

/// Stateful manager for importing raw data.
/// It supports all data and exact round-trips
class RawDataImportManager {
  // === dependencies ===
  final DBService db;
  final Future<void> Function(AppPrefs) updatePrefs;
  // === State ===
  final candidates = <RawDataFile>[];
  // benchmark
  final timings = <String, Duration>{};

  /// Can import if we have candidates, and at least 1 record
  int get canImportFileCount => candidates.isNotEmpty ? candidates.fold<int>(0, (p, c) => p + (c.isOk ? 1 : 0)) : 0;

  RawDataImportManager(this.db, this.updatePrefs);

  Future<void> scan(Directory folder) async {
    final t0 = DateTime.now();
    await Future.delayed(Duration(milliseconds: 300));
    // start fresh
    candidates.clear();
    // Look what we have
    final files = folder.listSync().whereType<File>().toList();

    for (final f in files) {
      // Get the extension (enum value) from the filename
      final e = extensionsSupport[f.path.split(".").lastOrNull];
      // add the file if supported extension
      if (e != null) {
        candidates.add(RawDataFile.fromFile(f, e));
      }
    }
    timings["scan"] = DateTime.now().difference(t0);
  }

  Future<void> preParse() async {
    final t0 = DateTime.now();

    // Simple inspection of file contents
    for (var c in candidates) {
      final (fields, nRec) = await parseFieldsAndCount(c.file, c.extension);
      c.fields = fields;
      c.nRecords = nRec;
      c.importer = FileImporter.getImporterRaw(c.role, db, updatePrefs);
    }
    timings["preParse"] = DateTime.now().difference(t0);
  }

  // Actually load the data and import to DB
  Future<ImportResult> import() async {
    final t0 = DateTime.now();

    final res = ImportResult();
    for (var c in candidates) {
      if (c.sizeBytes == 0) {
        continue; // Skip empty files
      }

      final importer = c.importer;

      // Import those that are ok.
      if (c.isOk && importer != null) {
        res.add(c.role, await importer.importAll(c.file));
      }
    }

    timings["import"] = DateTime.now().difference(t0);
    return res;
  }
}
