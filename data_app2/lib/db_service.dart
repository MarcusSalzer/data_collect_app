import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';
import 'package:data_app2/repos/evt_repo.dart';
import 'package:data_app2/repos/evt_type_repo.dart';
import 'package:data_app2/repos/location_repo.dart';
import 'package:data_app2/repos/user_schema_repos.dart';
import 'package:isar_community/isar.dart';

/// Wrapper repository for all DB access
class DBService {
  // --- events ---
  final EvtRepo evts;
  final EvtTypeRepo evtTypes;
  final EvtCatRepo evtCats;
  final LocationRepo locations;

  // --- UserTables ---
  final UserRowRepo userRows;
  final UserColumnRepo userColumns;
  final UserTableRepo userTables;
  final UserEnumRepo userEnums;
  final UserEnumValueRepo userEnumValues;

  final Isar isar;

  String? get dbFolder => isar.directory;

  DBService(this.isar)
    : evts = EvtRepo(isar),
      evtTypes = EvtTypeRepo(isar),
      evtCats = EvtCatRepo(isar),
      locations = LocationRepo(isar),
      userRows = UserRowRepo(isar),
      userColumns = UserColumnRepo(isar),
      userTables = UserTableRepo(isar),
      userEnums = UserEnumRepo(isar),
      userEnumValues = UserEnumValueRepo(isar);

  /// populate necessary default records if missing
  Future<void> ensureReady() async {
    // await evtCats.ensureReady();
  }

  Future<void> clear() async {
    await isar.writeTxn(() async => await isar.clear());
  }

  /// Check DB for dangling EvtType references
  Future<List<int>> danglingTypeRefs() async {
    final [refs, existing] = await Future.wait([evts.allReferencedTypeIds(), evtTypes.allIds()]);

    final dangling = refs.difference(existing).toList();
    dangling.sort();
    return dangling;
  }

  // create new types at missing ids.
  Future<List<int>> fillDanglingTypeRefs() async {
    final ids = await danglingTypeRefs();
    final created = <int>[];
    for (var i in ids) {
      final newId = await evtTypes.update(EvtTypeRec(i, "_new_type_$i"));
      created.add(newId);
    }
    return created;
  }

  Future<(Iterable<EvtTypeRec>, Iterable<EvtCatRec>)> allTypesAndCats() async {
    return (await evtTypes.all(), await evtCats.all());
  }
}
