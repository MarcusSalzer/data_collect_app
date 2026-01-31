import 'package:data_app2/repos/evt_cat_repo.dart';
import 'package:data_app2/repos/evt_repo.dart';
import 'package:data_app2/repos/event_type_repo.dart';
import 'package:data_app2/repos/prefs_repo.dart';
import 'package:data_app2/repos/tabular_repo.dart';
import 'package:isar_community/isar.dart';

/// Wrapper repository for all DB access
class DBService {
  final PrefsRepo prefs;
  final EvtRepo events;
  final EvtTypeRepo eventTypes;
  final TabularRepo tabular;
  final EvtCatRepo categories;

  final Isar _isar;

  String? get dbFolder => _isar.directory;

  DBService(this._isar)
    : prefs = PrefsRepo(_isar),
      events = EvtRepo(_isar),
      eventTypes = EvtTypeRepo(_isar),
      tabular = TabularRepo(_isar),
      categories = EvtCatRepo(_isar);
}
