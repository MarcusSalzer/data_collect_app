import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/local_datetime.dart';

abstract class EvtBase {
  const EvtBase();
  int get typeId;
  LocalDateTime? get start;
  LocalDateTime? get end;

  /// Get event duration (computed from UTC time)
  Duration? get duration {
    final s = start?.asUtc;
    final e = end?.asUtc;
    if (s == null || e == null) {
      return null;
    }
    return e.difference(s);
  }
}

class EvtDraft extends EvtBase implements Draft<EvtRec> {
  @override
  int typeId;
  @override
  LocalDateTime? start;
  @override
  LocalDateTime? end;

  EvtDraft(this.typeId, {required this.start, required this.end});

  /// Create a record in the current local timezone
  EvtDraft.inCurrentTZ(this.typeId, {required DateTime? start, required DateTime? end})
    : start = (start == null) ? null : LocalDateTime.fromDateTimeLocalTZ(start),
      end = (end == null) ? null : LocalDateTime.fromDateTimeLocalTZ(end) {
    if (start != null && start.isUtc) {
      throw ArgumentError("expects local time");
    }
    if (end != null && end.isUtc) {
      throw ArgumentError("expects local time");
    }
  }

  @override
  EvtRec toRec(int id) {
    return EvtRec(id, typeId, start: start, end: end);
  }

  @override
  bool operator ==(Object other) =>
      other is EvtDraft && typeId == other.typeId && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(typeId, start, end);
}

class EvtRec extends EvtBase implements Identifiable {
  const EvtRec(this.id, this.typeId, {required this.start, required this.end});

  @override
  final int id;
  // === fields ===
  @override
  final int typeId;
  @override
  final LocalDateTime? start;
  @override
  final LocalDateTime? end;

  // EvtRec.inCurrentTZ(this.id, int typeId, {required super.start, required super.end})
  //   : super.inCurrentTZ(typeId: typeId);

  @override
  EvtDraft toDraft() {
    return EvtDraft(typeId, start: start, end: end);
  }

  /// Sloppy factory based on the draft constructor
  factory EvtRec.inCurrentTZ(int id, int typeId, {required DateTime? start, required DateTime? end}) {
    return EvtDraft.inCurrentTZ(typeId, start: start, end: end).toRec(id);
  }
}
