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

  /// Export all data
  Future<Map<String, int>> exportAllData(
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
      EvtCsvCodec(typMan, locMan),
      "events_all.csv",
    );

    // --------- Event Types ---------
    final nType = await _saveCsv<EvtTypeDraft>(
      typMan.allTypes.map((e) => e.toDraft()), // all after reload
      EvtTypeCsvCodec.fromTypeManager(typMan),
      "event_types.csv",
    );

    // --------- Event Cats ---------
    final nCat = await _saveCsv<EvtCatDraft>(
      (await db.evtCats.all()).map((r) => r.toDraft()),
      EvtCatCsvCodec(),
      "event_categories.csv",
    );

    // --------- Locations ---------
    final nLoc = await _saveCsv<LocationDraft>(
      locMan.all.map((r) => r.toDraft()),
      LocationCsvCodec(),
      "locations.csv",
    );

    // --------- Preferences ---------
    PrefsIo.store(prefs, File(p.join(folderPath, "prefs.json")));

    return {"events": nEvt, "types": nType, "categories": nCat, "locations": nLoc};
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
}

class ExportError implements Exception {
  String msg;
  ExportError(this.msg);

  @override
  String toString() {
    return "Export error: $msg";
  }
}
