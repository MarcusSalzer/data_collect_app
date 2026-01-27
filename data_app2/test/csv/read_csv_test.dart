import 'package:data_app2/csv/evt_csv_adapter.dart';
import 'package:data_app2/csv/evt_type_csv_adapter.dart';
import 'package:data_app2/data/evt_draft.dart';
import 'package:data_app2/data/evt_rec.dart';
import 'package:data_app2/data/evt_type_rec.dart';
import 'package:data_app2/util/colors.dart';
import 'package:data_app2/event_type_manager.dart';
import 'package:data_app2/local_datetime.dart';

import 'package:test/test.dart';

/// Dummy function for types
EvtTypeRec resolveType(int typeId) {
  return EvtTypeRec(id: typeId, name: "Type$typeId");
}

final evtTypeMan = EvtTypeManager(
  types: [
    EvtTypeRec(id: 1, name: "Type1"),
    EvtTypeRec(id: 2, name: "Type2"),
  ],
);

void main() {
  // test type
  final typeId = evtTypeMan.all.first.id;
  final typeName = evtTypeMan.all.first.name;
  if (typeId == null) throw Exception("type should exist");

  test('read single Event, raw', () {
    final adapter = EvtCsvAdapterRaw();

    final loaded = adapter.fromRow("33,$typeId,123,10123,456,10456");

    expect(loaded, EvtRec(id: 33, typeId: typeId, start: LocalDateTime(123, 10123), end: LocalDateTime(456, 10456)));
  });
  test('read single Event, human', () {
    final adapter = EvtCsvAdapter();

    final loaded = adapter.fromRow("33,$typeName,1970-01-01T05:00:00Z,18000,1970-01-01T05:00:10Z,18000");

    expect(
      loaded,
      EvtDraft(
        id: 33,
        typeName: typeName,
        start: LocalDateTime(18000 * 1000, 36000 * 1000),
        end: LocalDateTime(18010 * 1000, 36010 * 1000),
      ),
    );
  });

  // EVENT TYPES

  test('read single EventType', () {
    final adapter = EvtTypeCsvAdapter();
    final col = ColorKey.values.last;
    // create a new event
    final loaded = adapter.fromRow("33,mytype,${col.name}");
    expect(loaded, EvtTypeRec(id: 33, name: "mytype", color: col));
  });
}
