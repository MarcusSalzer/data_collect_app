import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/csv/location_csv.dart';
import 'package:data_app2/csv/evt_csv.dart';
import 'package:data_app2/csv/evt_type_csv.dart';
import 'package:data_app2/csv/evt_cat_csv.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/util/enums.dart';

/// keep track of a repo and a decode function [S] -> [R].
class ImportDefRaw<S, R extends Identifiable> {
  final CrudRepo<R, Draft<R>, dynamic> repo;
  R Function(S) decodeOne;
  ImportDefRaw(this.repo, this.decodeOne);

  /// Store a single record to database (slow, but avoids list in memory)
  Future<int> save(S serialized) async {
    final id = await repo.update(decodeOne(serialized));
    return id;
  }

  /// Store all records to database at once (fast, but will make a list in memory)
  Future<int> saveAll(Iterable<S> rows) async {
    final ids = await repo.updateAll(rows.map(decodeOne));
    return ids.length;
  }
}

/// keep track of a repo and a decode function.
class ImportDefRawCsv<R extends Identifiable> extends ImportDefRaw<CsvRow, R> {
  ImportDefRawCsv(super.repo, super.decodeOne);
}

/// What can be imported from CSV?
ImportDefRawCsv? getImportDefCsv(ImportFileRole role, DBService db, {String sep = ","}) {
  return switch (role) {
    ImportFileRole.events => ImportDefRawCsv<EvtRec>(db.evts, EvtCsvCodecRaw(sep: sep).build),
    ImportFileRole.eventTypes => ImportDefRawCsv<EvtTypeRec>(db.evtTypes, EvtTypeCsvCodecRaw(sep: sep).build),
    ImportFileRole.eventCats => ImportDefRawCsv<EvtCatRec>(db.evtCats, EvtCatCsvCodecRaw(sep: sep).build),
    ImportFileRole.locations => ImportDefRawCsv<LocationRec>(db.locations, LocationCsvCodecRaw(sep: sep).build),
    // if no CSV support:
    _ => null,
  };
}

/// What can be imported from Ndjson?
ImportDefRaw<Map<String, dynamic>, Identifiable>? getImportDefNdjson(ImportFileRole role, DBService db) {
  return switch (role) {
    ImportFileRole.blobSchemas => ImportDefRaw<Map<String, dynamic>, BlobSchemaRec>(
      db.blobSchemas,
      BlobSchemaRec.fromJson,
    ),
    // if no Ndjson support:
    _ => null,
  };
}

/// Encapsulates all logic for reading and importing a file.
sealed class FileImporter {
  Future<int> importAll(File f);
  Set<String> get requiredFields;

  /// get a instance for importing some sort of data
  static FileImporter? getImporterRaw(ImportFileRole role, DBService db, Future<void> Function(AppPrefs) updatePrefs) {
    return switch (role) {
      ImportFileRole.events => CsvFileImporter(EvtCsvCodecRaw(sep: ","), db.evts.updateAll),
      ImportFileRole.eventTypes => CsvFileImporter(EvtTypeCsvCodecRaw(sep: ","), db.evtTypes.updateAll),
      ImportFileRole.eventCats => CsvFileImporter(EvtCatCsvCodecRaw(sep: ","), db.evtCats.updateAll),
      ImportFileRole.locations => CsvFileImporter(LocationCsvCodecRaw(sep: ","), db.locations.updateAll),
      ImportFileRole.enums => NdjsonImporter(UserEnumHydrated.fromJson, (a) async {
        await db.userEnumValues.updateAll(a.map((e) => e.values).flattened);
        await db.userEnums.updateAll(a.map((e) => e.recOnly()));
      }, {"id", "values", "name"}),
      ImportFileRole.blobs => NdjsonImporter(UserBlobRec.fromJson, db.blobs.updateAll, {"id", "schemaId", "values"}),
      ImportFileRole.blobSchemas => NdjsonImporter(BlobSchemaRec.fromJson, db.blobSchemas.updateAll, {"id", "fields"}),
      ImportFileRole.prefs => SingleTextImporter((t) async => await updatePrefs(AppPrefs.fromJson(jsonDecode(t)))),
      ImportFileRole.unknown => null,
    };
  }
}

/// imports one object from a text based (e.g. JSON) file
class SingleTextImporter<T> extends FileImporter {
  final Future<void> Function(String) cb;

  SingleTextImporter(this.cb);

  @override
  Set<String> get requiredFields => {};

  @override
  Future<int> importAll(File f) async {
    await cb((await f.readAsString()));
    return 1;
  }
}

/// Skips header and imports each line as an object.
class CsvFileImporter<T> extends FileImporter {
  final CsvCodecRW codec;
  final Future<void> Function(Iterable<T>) saveMultiple;
  CsvFileImporter(this.codec, this.saveMultiple);

  @override
  Set<String> get requiredFields => codec.schema.requiredCols;

  /// Import all objects from csv. TODO: Batched save callls?
  @override
  Future<int> importAll(File f) async {
    final rowStream = parseCsvRowsStream(f.openRead().transform(utf8.decoder).transform(const LineSplitter()));
    final objs = <T>[];
    await for (final r in rowStream) {
      objs.add(codec.build(r));
    }

    await saveMultiple(objs);
    return objs.length;
  }
}

/// Skips header and imports each line as an object.
class NdjsonImporter<T> extends FileImporter {
  final T Function(Map<String, dynamic> json) toObject;
  final Future<void> Function(Iterable<T>) saveMultiple;

  @override
  final Set<String> requiredFields;

  NdjsonImporter(this.toObject, this.saveMultiple, this.requiredFields);

  /// Import all objects from csv. TODO: Batched save callls?
  @override
  Future<int> importAll(File f) async {
    final rowStream = f.openRead().transform(utf8.decoder).transform(const LineSplitter());
    final objs = <T>[];
    await for (final r in rowStream) {
      final j = jsonDecode(r);
      if (j is! Map<String, dynamic>) {
        throw FormatException("[Ndjson] each line must be an object with string keys.");
      }
      objs.add(toObject(j));
    }

    await saveMultiple(objs);
    return objs.length;
  }
}
