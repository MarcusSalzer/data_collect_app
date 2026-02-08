import 'package:data_app2/repos/evt_cat_repo.dart';
import 'package:data_app2/repos/evt_repo.dart';
import 'package:data_app2/repos/evt_type_repo.dart';
import 'package:data_app2/repos/tabular_repo.dart';
import 'package:isar_community/isar.dart';

/// Wrapper repository for all DB access
class DBService {
  final EvtRepo events;
  final EvtTypeRepo eventTypes;
  final TabularRepo tabular;
  final EvtCatRepo categories;

  final Isar isar;

  String? get dbFolder => isar.directory;

  DBService(this.isar)
    : events = EvtRepo(isar),
      eventTypes = EvtTypeRepo(isar),
      tabular = TabularRepo(isar),
      categories = EvtCatRepo(isar);

  Future<void> clear() async {
    await isar.writeTxn(() async => await isar.clear());
  }
}
