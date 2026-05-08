// user_schema_repos.dart

import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/util/enums.dart';
import 'package:isar_community/isar.dart';

class UserEnumRepo extends CrudRepo<UserEnumRec, UserEnumDraft, UserEnum> {
  UserEnumRepo(super.isar)
    : super(
        draftToIsar: (d) => UserEnum(d.name),
        recToIsar: (r) => UserEnum(r.name)..id = r.id,
        fromIsar: (i) => UserEnumRec(i.id, name: i.name),
      );
  @override
  IsarCollection<UserEnum> get coll => isar.userEnums;
  @override
  QueryBuilder<UserEnum, int, QQueryOperations> get idProp => coll.where().idProperty();
}

class UserEnumValueRepo extends CrudRepo<UserEnumValueRec, UserEnumValueDraft, UserEnumValue> {
  UserEnumValueRepo(super.isar)
    : super(
        draftToIsar: (d) => UserEnumValue(d.enumId, d.name),
        recToIsar: (r) => UserEnumValue(r.enumId, r.name)..id = r.id,
        fromIsar: (i) => UserEnumValueRec(i.id, enumId: i.enumId, name: i.name),
      );
  @override
  IsarCollection<UserEnumValue> get coll => isar.userEnumValues;
  @override
  QueryBuilder<UserEnumValue, int, QQueryOperations> get idProp => coll.where().idProperty();

  Future<List<UserEnumValueRec>> byEnum(int enumId) async {
    return (await coll.where().enumIdEqualTo(enumId).findAll()).map(fromIsar).toList();
  }

  /// Delete a EnumValue, if it is not referenced by some TODO
  Future<DeleteResult> deleteIfUnreferenced(int id) async {
    throw UnimplementedError("Complicated since there is no unique field for the reference");
    // final didDelete = await super.forceDelete(id);
    // return didDelete ? DeleteResult.deleted : DeleteResult.notFound;
  }
}

class UserColumnRepo extends CrudRepo<UserColumnRec, UserColumnDraft, UserColumn> {
  UserColumnRepo(super.isar)
    : super(
        draftToIsar: (d) => UserColumn(d.name, d.dtype, enumId: d.enumId),
        recToIsar: (r) => UserColumn(r.name, r.dtype, enumId: r.enumId)..id = r.id,
        fromIsar: (i) => UserColumnRec(i.id, name: i.name, dtype: i.dtype, enumId: i.enumId),
      );
  @override
  IsarCollection<UserColumn> get coll => isar.userColumns;
  @override
  QueryBuilder<UserColumn, int, QQueryOperations> get idProp => coll.where().idProperty();
}

class UserTableRepo extends CrudRepo<UserTableRec, UserTableDraft, UserTable> {
  UserTableRepo(super.isar)
    : super(
        draftToIsar: (d) => UserTable(d.name, d.columnIds),
        recToIsar: (r) => UserTable(r.name, r.columnIds)..id = r.id,
        fromIsar: (i) => UserTableRec(i.id, name: i.name, columnIds: i.columnIds),
      );
  @override
  IsarCollection<UserTable> get coll => isar.userTables;
  @override
  QueryBuilder<UserTable, int, QQueryOperations> get idProp => coll.where().idProperty();
}

class UserRowRepo extends CrudRepo<UserRowRec, UserRowDraft, UserRow> {
  UserRowRepo(super.isar)
    : super(
        draftToIsar: (d) =>
            UserRow(tableId: d.tableId, eventId: d.eventId, timestampMillis: d.timestampMillis, values: d.values),
        recToIsar: (r) =>
            UserRow(tableId: r.tableId, eventId: r.eventId, timestampMillis: r.timestampMillis, values: r.values)
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
  IsarCollection<UserRow> get coll => isar.userRows;
  @override
  QueryBuilder<UserRow, int, QQueryOperations> get idProp => coll.where().idProperty();

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
