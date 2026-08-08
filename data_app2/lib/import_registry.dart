import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/csv/csv_row.dart';
import 'package:data_app2/csv/location_csv.dart';
import 'package:data_app2/csv/evt_csv.dart';
import 'package:data_app2/csv/evt_type_csv.dart';
import 'package:data_app2/csv/evt_cat_csv.dart';
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

// class NdjsonParser<>{

// }
