import 'package:data_app2/colors.dart';
import 'package:data_app2/db_service.dart' show Event, EventType;
import 'package:data_app2/local_datetime.dart';

/// Record class to hold an event
class EvtRec {
  int? id;
  int typeId;
  // Timestamps
  LocalDateTime? start;
  LocalDateTime? end;

  EvtRec({
    required this.id,
    required this.typeId,
    this.start,
    this.end,
  });

  /// Create a record in the current local timezone
  EvtRec.inCurrentTZ({
    this.id,
    required this.typeId,
    required DateTime? start,
    required DateTime? end,
  }) {
    if (start != null) {
      if (start.isUtc) throw ArgumentError("expects local time");
      this.start = LocalDateTime.fromDateTimeLocalTZ(start);
    }
    if (end != null) {
      if (end.isUtc) throw ArgumentError("expects local time");
      this.end = LocalDateTime.fromDateTimeLocalTZ(end);
    }
  }

  // Get event duration (computed from UTC time)
  Duration? get duration {
    final s = start?.asUtc;
    final e = end?.asUtc;
    if (s == null || e == null) {
      return null;
    }
    return e.difference(s);
  }

  @override
  String toString() {
    return "Evt($id | type: $typeId | Local: ${start?.asLocal} - ${end?.asLocal} | UTC: ${start?.asUtc} - ${end?.asUtc})";
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

  /// Update from Isar Event
  factory EvtRec.fromIsar(Event evt) {
    // millisecond timestamps
    final sU = evt.startUtcMillis;
    final sL = evt.startLocalMillis;
    final eU = evt.endUtcMillis;
    final eL = evt.endLocalMillis;

    return EvtRec(
      id: evt.id,
      typeId: evt.typeId,
      start: (sL != null && sU != null) ? LocalDateTime(sU, sL) : null,
      end: (eL != null && eU != null) ? LocalDateTime(eU, eL) : null,
    );
  }

  /// Convert to Isar Event
  Event toIsar() {
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

  EvtRec copyWith({
    int? id,
    int? typeId,
    LocalDateTime? start,
    LocalDateTime? end,
  }) {
    return EvtRec(
      id: id ?? this.id,
      typeId: typeId ?? this.typeId,
      start: start ?? this.start?.copyWith(),
      end: end ?? this.end?.copyWith(),
    );
  }
}

/// Record class to hold an event type
class EvtTypeRec {
  int? id;
  String name;
  ColorKey color;
  int? categoryId;

  EvtTypeRec({this.id, required this.name, this.color = ColorKey.base});

  @override
  String toString() {
    return "($id, $name, $color)";
  }

  @override
  bool operator ==(Object other) =>
      other is EvtTypeRec &&
      id == other.id &&
      name == other.name &&
      color == other.color &&
      categoryId == other.categoryId;

  @override
  int get hashCode => Object.hash(id, name);

  /// Create from Isar record
  factory EvtTypeRec.fromIsar(EventType et) {
    return EvtTypeRec(id: et.id, name: et.name, color: et.color);
  }

  /// Make Isar object to save
  EventType toIsar() {
    final et = EventType(name, color, categoryId);
    // add id if it has
    final currentId = id;
    if (currentId != null) et.id = currentId;
    return et;
  }

  EvtTypeRec copyWith({int? id, String? name, ColorKey? color}) {
    return EvtTypeRec(
        id: id ?? this.id, name: name ?? this.name, color: color ?? this.color);
  }
}
