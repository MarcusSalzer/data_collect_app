import 'package:data_app2/colors.dart';
import 'package:data_app2/csv/csv_format.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/event_type_repository.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/user_events.dart';

import 'package:test/test.dart';

EvtTypeRec resolveType(int typeId) {
  return EvtTypeRec(id: typeId, name: "Type$typeId");
}

final evtTypeRepo = EvtTypeRepository(types: [
  EvtTypeRec(id: 1, name: "Type1"),
  EvtTypeRec(id: 2, name: "Type2"),
]);

// extension _Count on String {
//   int countMatches(String needle) {
//     return needle.allMatches(this).length;
//   }
// }

void main() {
  // test type
  final typeId = evtTypeRepo.all.first.id;
  final typeName = evtTypeRepo.all.first.name;
  if (typeId == null) throw Exception("type should exist");

  test('write single Event, raw', () {
    final adapter = EventCsvAdapter(",", SchemaLevel.raw, evtTypeRepo);

    // create a new event
    final evtRec = EvtRec(
      id: 33,
      typeId: typeId,
      start: LocalDateTime(123, 10123),
      end: LocalDateTime(456, 10456),
    );

    final row = adapter.toRow(evtRec);
    expect(adapter.header,
        "id,type_id,start_utc_ms,start_local_ms,end_utc_ms,end_local_ms");
    expect(row, "33,$typeId,123,10123,456,10456");
  });
  test('write single Event, human', () {
    final adapter = EventCsvAdapter(",", SchemaLevel.human, evtTypeRepo);

    // create a new event
    final evtRec = EvtRec(
      id: 33,
      typeId: typeId,
      start: LocalDateTime(18000 * 1000, 36000 * 1000),
      end: LocalDateTime(18010 * 1000, 36010 * 1000),
    );

    final row = adapter.toRow(evtRec);
    expect(adapter.header,
        "id,type_name,start_utc_dt,start_local_dt,end_utc_dt,end_local_dt");
    expect(row,
        "33,$typeName,1970-01-01T05:00:00Z,1970-01-01T10:00:00,1970-01-01T05:00:10Z,1970-01-01T10:00:10");
  });

  // EVENT TYPES

  test('write single EventType, raw', () {
    final adapter = EventTypeCsvAdapter(";", SchemaLevel.raw);
    final col = ColorKey.values.last;
    // create a new event
    final evtRec = EvtTypeRec(id: 33, name: "mytype", color: col);

    final row = adapter.toRow(evtRec);
    expect(row, "33;mytype;${col.index}");
  });

  test('write single EventType, human', () {
    final adapter = EventTypeCsvAdapter(",", SchemaLevel.human);
    final col = ColorKey.values.last;
    // create a new event
    final evtRec = EvtTypeRec(id: 33, name: "mytype", color: col);

    final row = adapter.toRow(evtRec);
    expect(row, "33,mytype,${col.name}");
  });
}
