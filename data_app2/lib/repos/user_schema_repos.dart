// user_schema_repos.dart

import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/isar_models.dart';
import 'package:isar_community/isar.dart';

class UserColumnRepo extends CrudRepo<UserColumnRec, UserColumnDraft, UserColumnIsar> {
  UserColumnRepo(super.isar)
    : super(
        draftToIsar: (d) => UserColumnIsar(d.name, d.dtype, enumId: d.enumId),
        recToIsar: (r) => UserColumnIsar(r.name, r.dtype, enumId: r.enumId)..id = r.id,
        fromIsar: (i) => UserColumnRec(i.id, name: i.name, dtype: i.dtype, enumId: i.enumId),
      );
  @override
  IsarCollection<UserColumnIsar> get coll => isar.userColumnIsars;
  @override
  QueryBuilder<UserColumnIsar, int, QQueryOperations> get idProp => coll.where().idProperty();
}

class UserTableRepo extends CrudRepo<UserTableRec, UserTableDraft, UserTableIsar> {
  UserTableRepo(super.isar)
    : super(
        draftToIsar: (d) => UserTableIsar(d.name, d.columnIds),
        recToIsar: (r) => UserTableIsar(r.name, r.columnIds)..id = r.id,
        fromIsar: (i) => UserTableRec(i.id, name: i.name, columnIds: i.columnIds),
      );
  @override
  IsarCollection<UserTableIsar> get coll => isar.userTableIsars;
  @override
  QueryBuilder<UserTableIsar, int, QQueryOperations> get idProp => coll.where().idProperty();
}

class UserRowRepo extends CrudRepo<UserRowRec, UserRowDraft, UserRowIsar> {
  UserRowRepo(super.isar)
    : super(
        draftToIsar: (d) =>
            UserRowIsar(tableId: d.tableId, eventId: d.eventId, timestampMillis: d.timestampMillis, values: d.values),
        recToIsar: (r) =>
            UserRowIsar(tableId: r.tableId, eventId: r.eventId, timestampMillis: r.timestampMillis, values: r.values)
              ..id = r.id,
        fromIsar: (i) => UserRowRec(
          i.id,
          tableId: i.tableId,
          eventId: i.eventId,
          timestampMillis: i.timestampMillis,
          values: i.values,
        ),
      );
  @override
  IsarCollection<UserRowIsar> get coll => isar.userRowIsars;
  @override
  QueryBuilder<UserRowIsar, int, QQueryOperations> get idProp => coll.where().idProperty();

  Future<List<UserRowRec>> byTable(int tableId) async {
    return (await coll.where().tableIdEqualTo(tableId).findAll()).map(fromIsar).toList();
  }

  Future<List<UserRowRec>> byTableAndEvent(int tableId, int eventId) async {
    return (await coll.where().tableIdEqualTo(tableId).filter().eventIdEqualTo(eventId).findAll())
        .map(fromIsar)
        .toList();
  }

  Future<List<UserRowRec>> byTableInTimeRange(int tableId, int fromMillis, int toMillis) async {
    return (await coll.where().tableIdEqualTo(tableId).filter().timestampMillisBetween(fromMillis, toMillis).findAll())
        .map(fromIsar)
        .toList();
  }
}
