import 'dart:convert';

import 'package:data_app2/contracts/crud_repo.dart';
import 'package:data_app2/data/user_schema.dart';
import 'package:data_app2/isar_models.dart';
import 'package:isar_community/isar.dart';

class BlobRepo extends CrudRepo<UserBlobRec, UserBlobDraft, UserBlobIsar> {
  BlobRepo(super.isar)
    : super(
        draftToIsar: (d) => UserBlobIsar(jsonEncode(d.values), schemaId: d.schemaId, eventId: d.eventId),
        recToIsar: (r) => UserBlobIsar(jsonEncode(r.values), schemaId: r.schemaId, eventId: r.eventId)..id = r.id,
        fromIsar: (i) => UserBlobRec(i.id, schemaId: i.schemaId, eventId: i.eventId, values: jsonDecode(i.json)),
      );
  @override
  IsarCollection<UserBlobIsar> get coll => isar.userBlobIsars;
  @override
  QueryBuilder<UserBlobIsar, int, QQueryOperations> get idProp => coll.where().idProperty();
}

  // class BlobSchemaRepo extends CrudRepo<UserEnumValueRec, UserEnumValueDraft, UserEnumValue> {
  //   BlobSchemaRepo(super.isar)
  //     : super(
  //         draftToIsar: (d) => UserEnumValue(d.enumId, d.name),
  //         recToIsar: (r) => UserEnumValue(r.enumId, r.name)..id = r.id,
  //         fromIsar: (i) => UserEnumValueRec(i.id, enumId: i.enumId, name: i.name),
  //       );
  //   @override
  //   IsarCollection<UserEnumValue> get coll => isar.userEnumValues;
  //   @override
  //   QueryBuilder<UserEnumValue, int, QQueryOperations> get idProp => coll.where().idProperty();
  // }
