import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/evt.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/repos/blob_repos.dart';
import 'package:data_app2/repos/evt_repo.dart';
import 'package:data_app2/repos/user_enum_repos.dart';
import 'package:logging/logging.dart';

class UserBlobEditVm extends EditVm<UserBlobRec, UserBlobDraft> {
  UserBlobEditVm(
    UserBlobRec? stored,
    this.schema,
    this.repo,
    this._enumRepo,
    this._enumValueRepo,
    this._evtRepo,
  ) : super(stored, stored?.toDraft() ?? UserBlobDraft(schema.id));

  final BlobSchemaRec schema;
  final BlobRepo repo;
  final UserEnumValueRepo _enumValueRepo;
  final UserEnumRepo _enumRepo;
  final EvtRepo _evtRepo;
  final Map<String, String?> _fieldErrors = {};
  String? errorFor(String field) => _fieldErrors[field];

  dynamic rawValue(String field) => draft.values[field];

  /// Get the string map of values for enum fields
  Map<String, Set<String>>? enumGroupValues;
  EvtRec? _linkedEvent;
  EvtRec? get linkedEvent => _linkedEvent;

  Future<void> load() async {
    final enums = await _enumRepo.byNames(schema.usesEnums());
    enumGroupValues = {for (var e in enums) e.name: await _enumValueRepo.stringValuesForGroup(e.id)};

    // If we have a linked event:
    if (draft.eventId case int evtId) {
      _linkedEvent = await _evtRepo.getById(evtId);
    }
    notifyListeners();
  }

  void setValue(String field, dynamic value) {
    if (value == null) {
      draft.values.remove(field);
    } else {
      draft.values[field] = value;
    }
    _fieldErrors[field] = null;
    notifyListeners();
  }

  /// Unlink event
  void unsetEvent() {
    _linkedEvent = null;
    draft.eventId = null;
    notifyListeners();
  }

  /// Link this blob to some stored event.
  void setEvent(EvtRec evt) {
    // Just to be safe...

    if (schema.evtLink case EvtLinkSpec link) {
      if (!link.acceptsEvtTyp(evt.typeId)) {
        Logger.root.severe("Tried linking blob (link: $link) to event of wrong type ($evt).");
        return;
      }
    } else {
      Logger.root.severe("Tried linking blob (null linkspec) to event.");
      return;
    }

    // The event is already loaded from DB, so we can set the reference directly.
    _linkedEvent = evt;
    draft.eventId = evt.id;
    notifyListeners();
  }

  String? _validateEnum(String group, dynamic value) {
    if (enumGroupValues == null) {
      return "Enums not loaded";
    }
    final gVals = enumGroupValues?[group];
    if (gVals == null) {
      return "No values";
    }
    return gVals.contains(value) ? null : "Invalid choice";
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
        // DTimestamp() => value is int ? null : 'Invalid date',
        DEnum(:final group) => _validateEnum(group, value),
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
