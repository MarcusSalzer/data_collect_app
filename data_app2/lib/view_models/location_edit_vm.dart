import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/location_manager.dart';
import 'package:data_app2/repos/location_repo.dart';
import 'package:data_app2/util/location_parsing.dart';

class LocationEditVm extends EditVm<LocationRec, LocationDraft> {
  // Raw text from the coordinate field, kept separate from the draft
  String coordRaw = '';
  String? coordError;

  LocationEditVm({LocationRec? existing, required LocationRepo repo, required this.manager})
    : super(existing, existing?.toDraft() ?? LocationDraft('', 0, 0), repo) {
    if (existing != null) {
      coordRaw = '${existing.lat}, ${existing.lng}';
    }
  }

  final LocationManager manager;

  bool get isValid => draft.name.isNotEmpty && coordError == null && coordRaw.isNotEmpty;

  @override
  bool get isDirty => super.isDirty && draft.name.isNotEmpty;

  void setName(String v) {
    draft.name = v.trim();
    notifyListeners();
  }

  void setCoordRaw(String raw) {
    coordRaw = raw;
    final parsed = tryParseCoordinates(raw);
    if (parsed != null) {
      draft.lat = parsed.lat;
      draft.lng = parsed.lng;
      coordError = null;
    } else {
      coordError = raw.isEmpty ? null : 'Unrecognized coordinate format';
    }
    notifyListeners();
  }

  @override
  save() async {
    final r = stored;

    try {
      if (r == null) {
        final savedId = await repo.create(draft);
        final saved = draft.toRec(savedId);
        manager.upsert(saved);
        stored = saved;
      } else {
        final updated = draft.toRec(r.id);
        await repo.update(updated);
        manager.upsert(updated);
        stored = updated;
      }
      errorMsg = null;
    } catch (e) {
      errorMsg = 'Save failed: $e';
    }
    notifyListeners();
  }
}
