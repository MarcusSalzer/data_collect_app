import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/repos/evt_cat_repo.dart';
import 'package:data_app2/repos/evt_repo.dart';
import 'package:data_app2/repos/evt_type_repo.dart';
import 'package:data_app2/repos/tabular_repo.dart';
import 'package:isar_community/isar.dart';

/// Wrapper repository for all DB access
class DBService {
  final EvtRepo evts;
  final EvtTypeRepo evtTypes;
  final TabularRepo tabular;
  final EvtCatRepo evtCats;

  final Isar isar;

  String? get dbFolder => isar.directory;

  DBService(this.isar)
    : evts = EvtRepo(isar),
      evtTypes = EvtTypeRepo(isar),
      tabular = TabularRepo(isar),
      evtCats = EvtCatRepo(isar);

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
