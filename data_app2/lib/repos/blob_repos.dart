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

class BlobSchemaRepo extends CrudRepo<BlobSchemaRec, BlobSchemaDraft, UserBlobSchemaIsar> {
  BlobSchemaRepo(super.isar)
    : super(
        draftToIsar: (d) =>
            UserBlobSchemaIsar(d.name, json: jsonEncode({for (final e in d.fields.entries) e.key: e.value.toJson()})),
        recToIsar: (r) =>
            UserBlobSchemaIsar(r.name, json: jsonEncode({for (final e in r.fields.entries) e.key: e.value.toJson()}))
              ..id = r.id,
        fromIsar: (i) => BlobSchemaRec(
          i.id,
          name: i.name,
          fields: {
            for (final e in (jsonDecode(i.json) as Map<String, dynamic>).entries)
              e.key: BlobFieldSpec.fromJson(e.value as Map<String, dynamic>),
          },
        ),
      );
  @override
  IsarCollection<UserBlobSchemaIsar> get coll => isar.userBlobSchemaIsars;
  @override
  QueryBuilder<UserBlobSchemaIsar, int, QQueryOperations> get idProp => coll.where().idProperty();
}
