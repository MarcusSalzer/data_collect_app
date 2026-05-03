import 'package:data_app2/csv/builtin_schemas.dart';
import 'package:data_app2/csv/evt_csv.dart';
import 'package:data_app2/csv/evt_type_csv.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/location_manager.dart';
import 'package:test/test.dart';

import '../test_util/dummy_data.dart';

/// Dummy function for types
EvtTypeRec resolveType(int typeId) {
  return EvtTypeRec(typeId, "Type$typeId");
}

final evtTypeMan = EvtTypeManager();
final locMan = LocationManager();

void main() {
  evtTypeMan.reloadFromModels(SimpleDummyData.getDummyEvtTypes(), SimpleDummyData.getDummyEvtCats());
  locMan.upsert(LocationRec(9, name: "my house", lat: 10, lng: 1));
  // test type
  final typeId = evtTypeMan.allTypes.first.id;
  final typeName = evtTypeMan.allTypes.first.name;

  test('write single Event Draft, no location', () {
    // create a new event
    final evtRec = EvtDraft(
      typeId,
      start: LocalDateTime.fromUtcISOAndOffset(utcIso: "1970-01-01T00:00:00Z", offsetMillis: 2000),
      end: LocalDateTime.fromUtcISOAndOffset(utcIso: "1970-01-01T00:01:00Z", offsetMillis: 3000),
    );

    final codec = EvtCsvCodec(evtTypeMan, locMan);
    final lines = codec.encodeWithHeader([evtRec]).toList();

    expect(lines[0], CsvSchemasConst.evt.writeCols.join(","));
    expect(lines[1], "$typeName,1970-01-01T00:00:00Z,2,1970-01-01T00:01:00Z,3,");
  });
  test('write single Event Draft, missing timestamp and location', () {
    // create a new event
    final evtRec = EvtDraft(
      typeId,
      start: LocalDateTime.fromUtcISOAndOffset(utcIso: "1970-01-01T00:00:00Z", offsetMillis: 2000),
      end: null,
    );

    final codec = EvtCsvCodec(evtTypeMan, locMan);
    final lines = codec.encodeWithHeader([evtRec]).toList();

    expect(lines[0], CsvSchemasConst.evt.writeCols.join(","));
    expect(lines[1], "$typeName,1970-01-01T00:00:00Z,2,,,");
  });
  test('write single Event Draft, missing timestamp, has location', () {
    final loc = locMan.all.first;
    // create a new event
    final evtRec = EvtDraft(
      typeId,
      start: LocalDateTime.fromUtcISOAndOffset(utcIso: "1970-01-01T00:00:00Z", offsetMillis: 2000),
      end: null,
      locationId: loc.id,
    );

    final codec = EvtCsvCodec(evtTypeMan, locMan);
    final lines = codec.encodeWithHeader([evtRec]).toList();

    expect(lines[0], CsvSchemasConst.evt.writeCols.join(","));
    expect(lines[1], "$typeName,1970-01-01T00:00:00Z,2,,,${loc.name}");
  });

  // EVENT TYPES

  test('write single EventType', () {
    final codec = EvtTypeCsvCodec.fromTypeManager(evtTypeMan);
    final cat = evtTypeMan.allCats.last;
    // create a new event
    final r = EvtTypeDraft("mytype", cat.id);
    final lines = codec.encodeWithHeader([r]).toList();

    expect(lines[0], "name,category");
    expect(lines[1], "mytype,${cat.name}");
  });
}
