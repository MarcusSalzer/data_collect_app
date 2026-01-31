// import 'package:data_app2/csv/evt_csv_adapter.dart';
// import 'package:data_app2/csv/evt_type_csv_adapter.dart';
// import 'package:data_app2/data/evt_old.dart';
// import 'package:data_app2/data/evt_type.dart';
// import 'package:data_app2/util/colors.dart';
// import 'package:data_app2/event_type_manager.dart';
// import 'package:data_app2/local_datetime.dart';
// import 'package:test/test.dart';

// /// Dummy function for types
// EvtTypeRec resolveType(int typeId) {
//   return EvtTypeRec(typeId, "Type$typeId");
// }

// final evtTypeMan = EvtTypeManager(types: [EvtTypeRec(1, "Type1"), EvtTypeRec(2, "Type2")]);

// void main() {
//   // test type
//   final typeId = evtTypeMan.all.first.id;
//   final typeName = evtTypeMan.all.first.name;

//   test('write single Event, raw', () {
//     final adapter = EvtCsvAdapterRaw();
//     // create a new event
//     final evtRec = EvtRec(id: 33, typeId: typeId, start: LocalDateTime(123, 10123), end: LocalDateTime(456, 10456));

//     final row = adapter.toRow(evtRec);
//     expect(adapter.header, "id,type_id,start_utc_ms,start_local_ms,end_utc_ms,end_local_ms");
//     expect(row, "33,$typeId,123,10123,456,10456");
//   });
//   test('write single Event, human', () {
//     final adapter = EvtCsvAdapter();

//     // create a new event
//     final evt = EvtDraftOld(
//       id: 33,
//       typeName: typeName,
//       start: LocalDateTime(18000 * 1000, 36000 * 1000),
//       end: LocalDateTime(18010 * 1000, 36010 * 1000),
//     );

//     final row = adapter.toRow(evt);
//     expect(adapter.header, "id,type_name,start_utc,start_offset_s,end_utc,end_offset_s");
//     expect(row, "33,$typeName,1970-01-01T05:00:00Z,18000,1970-01-01T05:00:10Z,18000");
//   });

//   // EVENT TYPES

//   test('write single EventType', () {
//     final adapter = EvtTypeCsvAdapter();
//     final col = ColorKey.values.last;
//     // create a new event
//     final evtRec = EvtTypeRec(33, "mytype", col);

//     final row = adapter.toRow(evtRec);
//     expect(row, "33,mytype,${col.name}");
//   });
// }
