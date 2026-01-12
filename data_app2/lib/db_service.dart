import 'package:data_app2/repos/event_repo.dart';
import 'package:data_app2/repos/event_type_repo.dart';
import 'package:data_app2/repos/prefs_repo.dart';
import 'package:data_app2/repos/tabular_repo.dart';
import 'package:isar_community/isar.dart';

/// Wrapper repository for all DB access
class DBService {
  final PrefsRepo prefs;
  final EventRepo events;
  final EventTypeRepo eventTypes;
  final TabularRepo tabular;

  final Isar _isar;

  String? get dbFolder => _isar.directory;

  DBService(this._isar)
    : prefs = PrefsRepo(_isar),
      events = EventRepo(_isar),
      eventTypes = EventTypeRepo(_isar),
      tabular = TabularRepo(_isar);
}
