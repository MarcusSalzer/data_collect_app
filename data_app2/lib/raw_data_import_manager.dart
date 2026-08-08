import 'dart:convert';
import 'dart:io';

import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/csv/infer_role.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/import_registry.dart';
import 'package:data_app2/importv2.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/util/enums.dart';

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

  RawDataFile(
    this.file,
    this.role,
    this.extension,
    this.sizeBytes,
  );
  factory RawDataFile.fromFile(File file, ImportFileExtension ext) => RawDataFile(
    file,
    roleFromFileName(file.path.split("/").last),
    ext,
    file.statSync().size,
  );
}

/// Stateful manager for importing raw data.
/// It supports all data and exact round-trips
class RawDataImportManager {
  // === dependencies ===
  final DBService db;
  // === State ===
  final candidates = <RawDataFile>[];
  // benchmark
  final timings = <String, Duration>{};

  /// Can import if we have candidates, and at least 1 record
  bool get canImport => candidates.isNotEmpty && candidates.fold<int>(0, (p, c) => p + (c.nRecords ?? 0)) > 0;

  RawDataImportManager(this.db);

  Future<void> scan(Directory folder) async {
    final t0 = DateTime.now();
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
    }
    timings["preParse"] = DateTime.now().difference(t0);
  }

  // Actually load the data and import to DB
  Future<ImportResult> import() async {
    final t0 = DateTime.now();

    final res = ImportResult();
    for (var c in candidates) {
      switch (c.extension) {
        case ImportFileExtension.csv:
          final importDef = getImportDefCsv(c.role, db);
          if (importDef == null) {
            throw FormatException("cannot import ${c.role} from ${c.extension}");
          }

          final rows = parseCsvRows(await c.file.readAsLines());
          final count = await importDef.saveAll(rows);
          res.add(c.role, count);
        // Many JSON objects
        case ImportFileExtension.ndjson:
          final importDef = getImportDefNdjson(c.role, db);
          if (importDef == null) {
            throw FormatException("cannot import ${c.role} from ${c.extension}");
          }
          final rows = <Map<String, dynamic>>[];
          for (var line in (await c.file.readAsLines())) {
            final map = jsonDecode(line);
            if (map is! Map<String, dynamic>) {
              throw FormatException("Needs maps with string keys");
            }
            rows.add(map);
          }
          final count = await importDef.saveAll(rows);
          res.add(c.role, count);
        // A single JSON object
        case ImportFileExtension.json:
          // For now, app prefs is the only thing we can import
          if (c.role != ImportFileRole.prefs) {
            throw FormatException("Only preferences can be imported as json.");
          }

          final text = await c.file.readAsString();
          final map = jsonDecode(text);
          if (map is! Map<String, dynamic>) {
            throw FormatException("Needs map with string keys");
          }
          // Attach prefs to import-results since they need to be loaded into app-state rather than a repo
          res.newPrefs = AppPrefs.fromJson(map);
      }
    }

    timings["import"] = DateTime.now().difference(t0);
    return res;
  }
}
