import 'package:data_app2/app_state.dart';
import 'package:data_app2/io.dart';

/// Record class to hold an event
class EvtRec {
  final int? id;
  final int typeId;
  final DateTime? start;
  final DateTime? end;

  EvtRec(this.id, this.typeId, this.start, this.end);

  @override
  String toString() {
    return "Evt($id, $typeId, $start, $end)";
  }

  @override
  bool operator ==(Object other) =>
      other is EvtRec &&
      id == other.id &&
      typeId == other.typeId &&
      start == other.start &&
      end == other.end;

  @override
  int get hashCode => Object.hash(id, typeId, start, end);
}

Future<(Iterable<EvtRec>, ImportableSummary)> prepareImportEvts(
    Iterable<String> rows, AppState app) async {
  final recs = <EvtRec>[];
  for (var r in rows) {
    recs.add(await eventRecfromRow(r.split(","), app));
  }
  final summary = ImportableSummary.fromEvtRecs(recs);
  return (recs, summary);
}

/// from [id] (optional), [typeId], [start], [end]
Future<EvtRec> eventRecfromRow(List<String> r, AppState app) async {
  if (r.length == 3) {
    final name = r[0].trim();
    final typeId = app.eventTypeId(name) ?? await app.newEventType(name);

    return EvtRec(
      null,
      typeId,
      DateTime.tryParse(r[1].trim()),
      DateTime.tryParse(r[2].trim()),
    );
  } else if (r.length == 4) {
    final name = r[0].trim();
    final typeId = app.eventTypeId(name) ?? await app.newEventType(name);
    return EvtRec(
      int.tryParse(r[0].trim()),
      typeId,
      DateTime.tryParse(r[2].trim()),
      DateTime.tryParse(r[3].trim()),
    );
  }
  throw FormatException("unexpected row length ${r.length}");
}
