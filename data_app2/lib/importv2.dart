import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/csv/evt_cat_csv.dart';
import 'package:data_app2/csv/evt_csv.dart';
import 'package:data_app2/csv/evt_type_csv.dart';
import 'package:data_app2/csv/infer_from_header.dart';
import 'package:data_app2/csv/location_csv.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/util/enums.dart';
import 'package:path/path.dart' as p;

class ImportRoleDef {
  final CsvSchema? schema;

  /// optional validation step
  final void Function(List<CsvRow> rows)? validate;

  /// main import logic (import and count)
  final Future<int> Function(List<CsvRow> rows) import;

  /// optional side effect after all files of this role
  final Future<void> Function()? afterAll;

  const ImportRoleDef({
    required this.schema,
    this.validate,
    required this.import,
    this.afterAll,
  });
}

Map<ImportFileRole, ImportRoleDef> getImportRoleDefinitions(AppState app) {
  return {
    ImportFileRole.eventCats: ImportRoleDef(
      schema: CsvSchemasConst.evtCat,
      import: (rows) async {
        final items = EvtCatCsvCodec().decode(rows).toList();
        final nSkip = await app.db.evtCats.createIfPossible(items);
        return items.length - nSkip;
      },
      afterAll: () async {
        final allCats = await app.db.evtCats.all();
        app.evtTypeManager.reloadFromModels(null, allCats);
      },
    ),

    ImportFileRole.eventTypes: ImportRoleDef(
      schema: CsvSchemasConst.evtType,
      validate: (rows) {
        final counts = <String, int>{};
        for (var name in rows.map((r) => r.req("name"))) {
          counts[name] = (counts[name] ?? 0) + 1;
        }

        final duplicates = counts.entries.where((e) => e.value > 1).map((e) => e.key);

        if (duplicates.isNotEmpty) {
          throw StateError("duplicate event names: ${duplicates.join(',')}");
        }
      },
      import: (rows) async {
        final items = EvtTypeCsvCodec.fromTypeManager(app.evtTypeManager).decode(rows);

        final created = await app.db.evtTypes.createAllThrowEarly(items);
        return created.length;
      },
      afterAll: () async {
        app.evtTypeManager.reloadFromModels(
          await app.db.evtTypes.all(),
          null,
        );
      },
    ),

    ImportFileRole.locations: ImportRoleDef(
      schema: CsvSchemasConst.location,
      import: (rows) async {
        final items = LocationCsvCodec().decode(rows);
        final created = await app.db.locations.createAllThrowEarly(items);
        return created.length;
      },
    ),

    ImportFileRole.events: ImportRoleDef(
      schema: CsvSchemasConst.evt,
      import: (rows) async {
        final items = EvtCsvCodec(
          app.evtTypeManager,
          app.locationManager,
        ).decode(rows);

        final created = await app.db.evts.createAll(items);
        return created.length;
      },
    ),

    ImportFileRole.unknown: ImportRoleDef(
      schema: null,
      import: (_) async => 0,
    ),
  };
}

ImportRoleDef getRoleDef(AppState app, ImportFileRole role) {
  return getImportRoleDefinitions(app)[role]!;
}

class ImportCandidate {
  final File file;
  final Set<String> cols;
  final int size;
  final ImportFileRole role;
  final CsvSchema? schema;

  ImportCandidate(this.file, this.cols, this.size, this.role, this.schema);

  String get name => file.path.split("/").last;

  bool colUsable(String col) {
    return (schema?.writeCols.contains(col) ?? false);
  }
}

class ImportCandidateCollection {
  final Map<ImportFileRole, List<ImportCandidate>> cands = {
    for (final r in ImportFileRole.values) r: <ImportCandidate>[],
  };

  /// Read-only access (avoid leaking mutability)
  List<ImportCandidate> of(ImportFileRole role) => List.unmodifiable(cands[role]!);

  /// Iterate all candidates (optionally filtered)
  Iterable<ImportCandidate> all({bool includeUnknown = false}) sync* {
    for (final entry in cands.entries) {
      if (!includeUnknown && entry.key == ImportFileRole.unknown) continue;
      yield* entry.value;
    }
  }

  void clear() {
    for (final list in cands.values) {
      list.clear();
    }
  }

  Future<void> addFile(File file) async {
    final cols = await getCsvHeaderCols(file);
    final role = roleFromName(p.basename(file.path));
    final size = (await file.stat()).size;

    cands[role]!.add(
      ImportCandidate(file, cols, size, role, CsvSchemasConst.byImportRole[role]),
    );
  }

  /// Useful for UI / flow decisions
  bool get canImport => cands.entries.any(
    (e) => e.key != ImportFileRole.unknown && e.value.isNotEmpty,
  );

  bool has(ImportFileRole role) => cands[role]!.isNotEmpty;

  int count(ImportFileRole role) => cands[role]!.length;

  @override
  String toString() {
    return cands.entries.map((e) => "${e.key.name}:${e.value.length}").join(", ");
  }
}

class ImportCandidateSummary<T> {
  final int count;
  final int? idOverlapCount;
  DateTime? earliest;
  DateTime? latest;

  List<T> items;

  ImportCandidateSummary(this.items, this.idOverlapCount) : count = items.length {
    // Timestamped?
    if (items case List<EvtRec> evts) {
      // counts first and last
      for (final r in evts) {
        final s = r.start?.asLocal;
        final e = r.end?.asLocal;
        if (s != null) {
          if (earliest == null || s.isBefore(earliest!)) {
            earliest = s;
          }
        }
        if (e != null) {
          if (latest == null || e.isAfter(latest!)) {
            latest = s;
          }
        }
      }
    }
  }
}

class ImportResult {
  final Map<ImportFileRole, int> counts = {};

  ImportResult();
  void add(ImportFileRole role, int n) {
    counts[role] = (counts[role] ?? 0) + n;
  }
}
