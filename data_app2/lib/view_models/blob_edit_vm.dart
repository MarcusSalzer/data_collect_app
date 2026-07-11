import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/blob_repos.dart';

class UserBlobEditVm extends EditVm<UserBlobRec, UserBlobDraft> {
  UserBlobEditVm(
    UserBlobRec? stored,
    this.schema, {
    required this.enumGroupValues,
    required this.repo,
  }) : super(stored, stored?.toDraft() ?? UserBlobDraft(schema.id));

  final BlobSchemaRec schema;
  final Map<String, Set<String>> enumGroupValues;
  final BlobRepo repo;

  final Map<String, String?> _fieldErrors = {};
  String? errorFor(String field) => _fieldErrors[field];

  dynamic rawValue(String field) => draft.values[field];

  void setValue(String field, dynamic value) {
    if (value == null) {
      draft.values.remove(field);
    } else {
      draft.values[field] = value;
    }
    _fieldErrors[field] = null;
    notifyListeners();
  }

  bool validate() {
    _fieldErrors.clear();
    var ok = true;
    for (final entry in schema.fields.entries) {
      final name = entry.key;
      final spec = entry.value;
      final value = draft.values[name];
      if (value == null) {
        if (!spec.nullable) {
          _fieldErrors[name] = 'Required';
          ok = false;
        }
        continue;
      }
      final typeError = switch (spec.type) {
        DInt() => value is int ? null : 'Must be a whole number',
        DDecimal() => value is num ? null : 'Must be a number',
        DText() => value is String ? null : "Must be a string",
        DBool() => value is bool ? null : 'Invalid',
        DTimestamp() => value is int ? null : 'Invalid date',
        DEnum(:final group) => (enumGroupValues[group] ?? <String>{}).contains(value) ? null : 'Invalid choice',
        // TODO: Handle this case.
        DDuration() => throw UnimplementedError(),
        // TODO: Handle this case.
        DTuple() => throw UnimplementedError(),
        // TODO: Handle this case.
      };
      if (typeError != null) {
        _fieldErrors[name] = typeError;
        ok = false;
      }
    }
    notifyListeners();
    return ok;
  }

  @override
  Future<void> save() async {
    if (!validate()) return;
    final storedId = stored?.id;
    try {
      if (storedId != null) {
        final updated = draft.toRec(storedId);
        await repo.update(updated);
        stored = updated;
      } else {
        final newId = await repo.create(draft);
        stored = draft.toRec(newId);
      }
    } catch (e) {
      errorMsg = 'Could not save: $e';
      notifyListeners();
    }
  }

  @override
  Future<bool> delete() async {
    final storedId = stored?.id;

    if (storedId == null) return false;

    try {
      final r = await repo.forceDelete(storedId);
      notifyListeners();
      return r;
    } catch (e) {
      errorMsg = 'Could not delete: $e';
      notifyListeners();
      return false;
    }
  }
}
