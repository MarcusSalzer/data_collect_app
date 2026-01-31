import 'package:data_app2/isar_models.dart';
import 'package:data_app2/local_datetime.dart';

/// Very similar to [EvtRec], but with optional id, and type as string instead of id.
@Deprecated("Use EvtDraft")
class EvtDraftOld {
  final int? id;
  final String typeName;
  final LocalDateTime? start;
  final LocalDateTime? end;

  const EvtDraftOld({required this.id, required this.typeName, required this.start, required this.end});

  /// get event draft from db
  /// throws if not in repo
  factory EvtDraftOld.fromIsar(Event e, String typeName) {
    return EvtDraftOld(
      id: e.id,
      typeName: typeName,
      start: LocalDateTime.maybeFromMillis(e.startUtcMillis, e.startLocalMillis),
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
      other is EvtDraftOld && id == other.id && typeName == other.typeName && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(id, typeName, start, end);
}

/// Record class to hold an event
@Deprecated("Use EvtRec")
class EvtRecOld {
  int? id;
  int typeId;
  // Timestamps
  LocalDateTime? start;
  LocalDateTime? end;

  EvtRecOld({required this.id, required this.typeId, this.start, this.end});

  @override
  String toString() {
    return "Evt($id | type: $typeId | Local: ${start?.asLocal} - ${end?.asLocal} | UTC: ${start?.asUtc} - ${end?.asUtc})";
  }

  @override
  int get hashCode => Object.hash(id, typeId, start, end);

  EvtRecOld copyWith({int? id, int? typeId, LocalDateTime? start, LocalDateTime? end}) {
    return EvtRecOld(
      id: id ?? this.id,
      typeId: typeId ?? this.typeId,
      start: start ?? this.start?.copyWith(),
      end: end ?? this.end?.copyWith(),
    );
  }
}
