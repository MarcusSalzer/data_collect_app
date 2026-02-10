import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';

class EvtTypeDraft extends Draft<EvtTypeRec> {
  EvtTypeDraft(this.name, [this.categoryId = EvtCatRepo.defaultId]);

  // === fields ===
  String name;
  int categoryId;

  @override
  String toString() {
    return "($name, cat: $categoryId)";
  }

  @override
  bool operator ==(Object other) => other is EvtTypeDraft && name == other.name && categoryId == other.categoryId;

  @override
  int get hashCode => Object.hash(name, categoryId);

  @override
  EvtTypeRec toRec(int id) {
    return EvtTypeRec(id, name, categoryId);
  }
}

class EvtTypeRec implements Identifiable {
  EvtTypeRec(this.id, this.name, [this.categoryId = EvtCatRepo.defaultId]);

  // === fields ===
  final String name;
  final int categoryId;
  @override
  final int id;

  @override
  String toString() {
    return "($id, $name, cat: $categoryId)";
  }

  @override
  EvtTypeDraft toDraft() {
    return EvtTypeDraft(name, categoryId);
  }
}
