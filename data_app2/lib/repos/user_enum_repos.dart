import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/util/enums.dart';
import 'package:isar_community/isar.dart';

class UserEnumRepo extends CrudRepo<UserEnumRec, UserEnumDraft, UserEnumIsar> {
  UserEnumRepo(super.isar)
    : super(
        draftToIsar: (d) => UserEnumIsar(d.name),
        recToIsar: (r) => UserEnumIsar(r.name)..id = r.id,
        fromIsar: (i) => UserEnumRec(i.id, name: i.name),
      );
  @override
  IsarCollection<UserEnumIsar> get coll => isar.userEnumIsars;
  @override
  QueryBuilder<UserEnumIsar, int, QQueryOperations> get idProp => coll.where().idProperty();
}

class UserEnumValueRepo extends CrudRepo<UserEnumValueRec, UserEnumValueDraft, UserEnumValueIsar> {
  UserEnumValueRepo(super.isar)
    : super(
        draftToIsar: (d) => UserEnumValueIsar(d.enumId, d.name),
        recToIsar: (r) => UserEnumValueIsar(r.enumId, r.name)..id = r.id,
        fromIsar: (i) => UserEnumValueRec(i.id, enumId: i.enumId, name: i.name),
      );
  @override
  IsarCollection<UserEnumValueIsar> get coll => isar.userEnumValueIsars;
  @override
  QueryBuilder<UserEnumValueIsar, int, QQueryOperations> get idProp => coll.where().idProperty();

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
