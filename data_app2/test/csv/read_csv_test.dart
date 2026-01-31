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

//   test('read single Event, raw', () {
//     final adapter = EvtCsvAdapterRaw();

//     final loaded = adapter.fromRow("33,$typeId,123,10123,456,10456");

//     expect(loaded, EvtRec(id: 33, typeId: typeId, start: LocalDateTime(123, 10123), end: LocalDateTime(456, 10456)));
//   });
//   test('read single Event, human', () {
//     final adapter = EvtCsvAdapter();

//     final loaded = adapter.fromRow("33,$typeName,1970-01-01T05:00:00Z,18000,1970-01-01T05:00:10Z,18000");

//     expect(
//       loaded,
//       EvtDraftOld(
//         id: 33,
//         typeName: typeName,
//         start: LocalDateTime(18000 * 1000, 36000 * 1000),
//         end: LocalDateTime(18010 * 1000, 36010 * 1000),
//       ),
//     );
//   });

//   // EVENT TYPES

//   test('read single EventType', () {
//     final adapter = EvtTypeCsvAdapter();
//     final col = ColorKey.values.last;
//     // create a new event
//     final loaded = adapter.fromRow("33,mytype,${col.name}");
//     expect(loaded, EvtTypeRec(33, "mytype", col));
//   });
// }
