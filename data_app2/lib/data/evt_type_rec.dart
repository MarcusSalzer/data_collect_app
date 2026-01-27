import 'package:data_app2/isar_models.dart';
import 'package:data_app2/util/colors.dart';

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
    return EvtTypeRec(id: id ?? this.id, name: name ?? this.name, color: color ?? this.color);
  }
}
