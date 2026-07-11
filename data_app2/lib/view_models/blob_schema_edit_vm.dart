import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/blob_repos.dart';
import 'package:isar_community/isar.dart';

class BlobSchemaEditVm extends EditVm<BlobSchemaRec, BlobSchemaDraft> {
  final BlobSchemaRepo repo;

  BlobSchemaEditVm(BlobSchemaRec? stored, this.repo)
    : super(stored, stored?.toDraft() ?? BlobSchemaDraft('', fields: {}));

  /// Valid if it has a name and at least one field.
  bool get isValid => draft.name.isNotEmpty && draft.fields.isNotEmpty;

  @override
  bool get isDirty => isValid && super.isDirty;

  /// Get all field names as a sorted list
  List<MapEntry<String, BlobFieldSpec>> get fieldList =>
      draft.fields.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

  Future<void> load() async {
    final storedId = stored?.id;
    if (storedId == null) return;

    // final valuesStored = await _db.userEnumValues.byEnum(storedId);
    // valueNameDrafts = valuesStored.map((v) => v.name).toSet();
    print("loaded, do we need additional data? maybe enum groups..");
    notifyListeners();
  }

  // === Edit methods ===
  void addField(String name, BlobFieldSpec spec) {
    draft.fields[name] = spec;
    notifyListeners();
  }

  void removeField(String name) {
    draft.fields.remove(name);
    notifyListeners();
  }

  void setName(String name) {
    draft.name = name;
    notifyListeners();
  }

  // === Storage methods ===
  @override
  Future<bool> delete() async {
    final stored = this.stored;
    if (stored == null) return false; // cannot delete if never saved

    final r = await repo.forceDelete(stored.id);
    return r;
  }

  @override
  save() async {
    try {
      stored = await repo.createOrUpdate(draft, stored?.id);
    } on IsarError catch (e) {
      if (e.message.contains("Unique")) {
        errorMsg = "Please give a unique name";
      } else {
        errorMsg = e.message;
      }
    } catch (e) {
      errorMsg = e.toString();
    }
    // always notify after
    notifyListeners();
  }
}
