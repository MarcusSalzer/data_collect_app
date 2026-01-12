import 'package:data_app2/isar_models.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/user_events.dart';

/// Very similar to [EvtRec], but with optional id, and type as string instead of id.
class EvtDraft {
  final int? id;
  final String typeName;
  final LocalDateTime? start;
  final LocalDateTime? end;

  const EvtDraft({
    required this.id,
    required this.typeName,
    required this.start,
    required this.end,
  });

  /// get event draft from db
  /// throws if not in repo
  factory EvtDraft.fromIsar(Event e, String typeName) {
    return EvtDraft(
      id: e.id,
      typeName: typeName,
      start: LocalDateTime.maybeFromMillis(
        e.startUtcMillis,
        e.startLocalMillis,
      ),
      end: LocalDateTime.maybeFromMillis(e.endUtcMillis, e.endLocalMillis),
    );
  }

  Event toIsar(int typeId) {
    final evt = Event(
      typeId: typeId,
      startLocalMillis: start?.localMillis,
      startUtcMillis: start?.utcMillis,
      endLocalMillis: end?.localMillis,
      endUtcMillis: end?.utcMillis,
    );
    // add id if it has
    final currentId = id;
    if (currentId != null) evt.id = currentId;

    return evt;
  }

  @override
  String toString() {
    return "Evtdraft($id, $typeName, $start, $end)";
  }

  @override
  bool operator ==(Object other) =>
      other is EvtDraft &&
      id == other.id &&
      typeName == other.typeName &&
      start == other.start &&
      end == other.end;

  @override
  int get hashCode => Object.hash(id, typeName, start, end);
}
