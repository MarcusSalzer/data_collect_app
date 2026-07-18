import 'dart:convert';
import 'dart:io';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/csv/evt_cat_csv.dart';
import 'package:data_app2/csv/evt_csv.dart';
import 'package:data_app2/csv/evt_type_csv.dart';
import 'package:data_app2/csv/location_csv.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/location_manager.dart';
import 'package:data_app2/prefs_io.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:path/path.dart' as p;

/// Handles data export.
///
/// Note that an export is a directory, containing a few files.
class CompleteExportService {
  /// Generate name based on UTC timestamp
  static String _genName(DateTime dt) {
    return Fmt.dtSecondSimple(dt.toUtc());
  }

  final String name;
  final Directory parent;

  String get folderPath => p.join(parent.path, name);

  CompleteExportService(this.parent, DateTime now) : name = _genName(now);

  /// Export all data (human schema variant)
  Future<Map<String, int>> exportAllDataHuman(
    DBService db,
    EvtTypeManager typMan,
    LocationManager locMan,
    AppPrefs prefs,
  ) async {
    // reload event types and categories
    final (t, c) = await db.allTypesAndCats();
    typMan.reloadFromModels(t, c);
    // reload locations
    final locs = await db.locations.all();
    locMan.reloadFromModels(locs);

    // --------- Events ---------
    final nEvt = await _saveCsv<EvtDraft>(
      // Map to draft. Id:s not needed at export.
      (await db.evts.all()).map((r) => r.toDraft()),
      EvtCsvCodecHuman(typMan, locMan),
      "events_all.csv",
    );

    // --------- Event Types ---------
    final nType = await _saveCsv<EvtTypeDraft>(
      typMan.allTypes.map((e) => e.toDraft()), // all after reload
      EvtTypeCsvCodecHuman.fromTypeManager(typMan),
      "event_types.csv",
    );

    // --------- Event Cats ---------
    final nCat = await _saveCsv<EvtCatDraft>(
      (await db.evtCats.all()).map((r) => r.toDraft()),
      EvtCatCsvCodecHuman(),
      "event_categories.csv",
    );

    // --------- Locations ---------
    final nLoc = await _saveCsv<LocationDraft>(
      locMan.all.map((r) => r.toDraft()),
      LocationCsvCodecHuman(),
      "locations.csv",
    );

    // --------- Preferences ---------
    PrefsIo.store(prefs, File(p.join(folderPath, "prefs.json")));

    // --------- Blob: schemas & records as separate files ---------
    final nBlobSchemas = await _saveNdjson(await db.blobSchemas.all(), "blob_schemas.ndjson");
    final nBlobs = await _saveNdjson(await db.blobs.all(), "blob_records.ndjson");

    // --------- Enums: Groups and values in same file ---------
    final nEnum = await _saveNdjson(await db.allEnumsWithValues(), "enums.ndjson");
    return {
      "events": nEvt,
      "types": nType,
      "categories": nCat,
      "locations": nLoc,
      "schemas": nBlobSchemas,
      "records": nBlobs,
      "enums": nEnum,
    };
  }

  /// Export all data (human schema variant)
  Future<Map<String, int>> exportAllDataRaw(
    DBService db,
    AppPrefs prefs,
  ) async {
    // --------- Events ---------
    final nEvt = await _saveCsv<EvtRec>(
      await db.evts.all(),
      EvtCsvCodecRaw(),
      "events_all.csv",
    );

    // --------- Event Types ---------
    final nType = await _saveCsv<EvtTypeRec>(
      await db.evtTypes.all(),
      EvtTypeCsvCodecRaw(),
      "event_types.csv",
    );

    // --------- Event Cats ---------
    final nCat = await _saveCsv<EvtCatRec>(
      await db.evtCats.all(),
      EvtCatCsvCodecRaw(),
      "event_categories.csv",
    );

    // --------- Locations ---------
    final nLoc = await _saveCsv<LocationRec>(
      await db.locations.all(),
      LocationCsvCodecRaw(),
      "locations.csv",
    );

    // --------- Preferences ---------
    PrefsIo.store(prefs, File(p.join(folderPath, "prefs.json")));

    // --------- Blob: schemas & records as separate files ---------
    final nBlobSchemas = await _saveNdjson(await db.blobSchemas.all(), "blob_schemas.ndjson");
    final nBlobs = await _saveNdjson(await db.blobs.all(), "blob_records.ndjson");

    // --------- Enums: Groups and values in same file ---------
    final nEnum = await _saveNdjson(await db.allEnumsWithValues(), "enums.ndjson");
    return {
      "events": nEvt,
      "types": nType,
      "categories": nCat,
      "locations": nLoc,
      "schemas": nBlobSchemas,
      "records": nBlobs,
      "enums": nEnum,
    };
  }

  /// Save some data with a compatible CSV writer
  Future<int> _saveCsv<T>(Iterable<T> records, CsvCodecWrite<T> writer, String filename) async {
    // prepare file
    final file = File(p.join(folderPath, filename));
    if (await file.exists()) {
      throw ExportError("Target (${file.path}) already exists.");
    }
    await file.create(recursive: true);

    // format content
    final lines = writer.encodeWithHeader(records).toList();
    // write contents
    await file.writeAsString(lines.join("\n"));
    // How many lines were written
    return lines.length;
  }

  /// Save some data as json lines
  Future<int> _saveNdjson(Iterable<Object> records, String filename) async {
    // prepare file
    final file = File(p.join(folderPath, filename));
    if (await file.exists()) {
      throw ExportError("Target (${file.path}) already exists.");
    }
    await file.create(recursive: true);
    final sink = file.openWrite();
    var count = 0;
    for (var r in records) {
      sink.writeln(jsonEncode(r));
      count++;
    }
    await sink.flush();
    await sink.close();
    return count;
  }
}

class ExportError implements Exception {
  String msg;
  ExportError(this.msg);

  @override
  String toString() {
    return "Export error: $msg";
  }
}
