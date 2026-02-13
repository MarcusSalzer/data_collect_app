import 'package:data_app2/csv/evt_csv.dart';
import 'package:data_app2/csv/evt_type_csv.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/evt_type_manager.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:test/test.dart';

import '../test_util/dummy_data.dart';

/// Dummy function for types
EvtTypeRec resolveType(int typeId) {
  return EvtTypeRec(typeId, "Type$typeId");
}

final evtTypeMan = EvtTypeManager();

void main() {
  evtTypeMan.reloadFromModels(SimpleDummyData.getDummyEvtTypes(), SimpleDummyData.getDummyEvtCats());
  // test type
  final typeId = evtTypeMan.allTypes.first.id;
  final typeName = evtTypeMan.allTypes.first.name;

  test('write single Event Draft, named types', () {
    // create a new event
    final evtRec = EvtDraft(
      typeId,
      start: LocalDateTime.fromUtcISOAndOffset(utcIso: "1970-01-01T00:00:00Z", offsetMillis: 2000),
      end: LocalDateTime.fromUtcISOAndOffset(utcIso: "1970-01-01T00:01:00Z", offsetMillis: 3000),
    );

    final codec = EvtCsvCodec(typMan: evtTypeMan);
    final lines = codec.encodeWithHeader([evtRec]).toList();

    expect(lines[0], "type,start_utc,start_offset_s,end_utc,end_offset_s");
    expect(lines[1], "$typeName,1970-01-01T00:00:00Z,2,1970-01-01T00:01:00Z,3");
  });
  test('write single Event Draft, missing timestamp', () {
    // create a new event
    final evtRec = EvtDraft(
      typeId,
      start: LocalDateTime.fromUtcISOAndOffset(utcIso: "1970-01-01T00:00:00Z", offsetMillis: 2000),
      end: null,
    );

    final codec = EvtCsvCodec(typMan: evtTypeMan);
    final lines = codec.encodeWithHeader([evtRec]).toList();

    expect(lines[0], "type,start_utc,start_offset_s,end_utc,end_offset_s");
    expect(lines[1], "$typeName,1970-01-01T00:00:00Z,2,,");
  });

  // EVENT TYPES

  test('write single EventType', () {
    final codec = EvtTypeCsvCodec();
    // create a new event
    final r = EvtTypeDraft("mytype", 1);
    final lines = codec.encodeWithHeader([r]).toList();

    expect(lines[0], "name,category");
    expect(lines[1], "mytype,1");
  });
}
