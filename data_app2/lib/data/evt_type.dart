import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/util/colors.dart';

class EvtTypeDraft extends Draft<EvtTypeRec> {
  EvtTypeDraft(this.name, [this.color = ColorKey.base, this.categoryId]);

  // === fields ===
  final String name;
  final ColorKey color;
  final int? categoryId;

  @override
  String toString() {
    return "($name, $color)";
  }

  EvtTypeDraft copyWith({int? id, String? name, ColorKey? color, int? categoryId}) {
    return EvtTypeDraft(name ?? this.name, color ?? this.color, categoryId ?? this.categoryId);
  }

  @override
  EvtTypeRec toRec(int id) {
    return EvtTypeRec(id, name, color, categoryId);
  }
}

class EvtTypeRec extends EvtTypeDraft implements Identifiable {
  EvtTypeRec(this.id, super.name, [super.color, super.categoryId]);

  // === fields ===
  @override
  final int id;

  @override
  String toString() {
    return "($id, $name, $color, $categoryId)";
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

  @override
  EvtTypeRec copyWith({int? id, String? name, ColorKey? color, int? categoryId}) {
    return EvtTypeRec(id ?? this.id, name ?? this.name, color ?? this.color, categoryId ?? this.categoryId);
  }

  @override
  EvtTypeDraft toDraft() {
    return EvtTypeDraft(name, color, categoryId);
  }
}
