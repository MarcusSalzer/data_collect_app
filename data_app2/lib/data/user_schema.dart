import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/users_schema.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
// ============ ENUMS ============

class UserEnumRec implements Identifiable {
  const UserEnumRec(this.id, {required this.name});
  @override
  final int id;
  final String name;
  @override
  UserEnumDraft toDraft() => UserEnumDraft(name);
}

class UserEnumDraft implements Draft<UserEnumRec> {
  UserEnumDraft(this.name);
  String name;
  @override
  UserEnumRec toRec(int id) => UserEnumRec(id, name: name);

  @override
  bool operator ==(Object other) => other is UserEnumDraft && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

// ============ ENUM VALUES ============

class UserEnumValueRec implements Identifiable {
  const UserEnumValueRec(this.id, {required this.enumId, required this.name});
  @override
  final int id;
  final int enumId;
  final String name;
  @override
  UserEnumValueDraft toDraft() => UserEnumValueDraft(enumId, name);
}

class UserEnumValueDraft implements Draft<UserEnumValueRec> {
  UserEnumValueDraft(this.enumId, this.name);
  int enumId;
  String name;
  @override
  UserEnumValueRec toRec(int id) => UserEnumValueRec(id, enumId: enumId, name: name);
}

// ============ USER TABLE THINGS (EXPERIMENTAL) ============

class UserColumnRec implements Identifiable {
  const UserColumnRec(this.id, {required this.name, required this.dtype, this.enumId});
  @override
  final int id;
  final String name;
  final DType dtype;
  final int? enumId;
  @override
  UserColumnDraft toDraft() => UserColumnDraft(name, dtype, enumId: enumId);
}

class UserColumnDraft implements Draft<UserColumnRec> {
  UserColumnDraft(this.name, this.dtype, {this.enumId});
  String name;
  DType dtype;
  int? enumId;
  @override
  UserColumnRec toRec(int id) => UserColumnRec(id, name: name, dtype: dtype, enumId: enumId);
}

class UserTableRec implements Identifiable {
  const UserTableRec(this.id, {required this.name, required this.columnIds});
  @override
  final int id;
  final String name;
  final List<int> columnIds;
  @override
  UserTableDraft toDraft() => UserTableDraft(name, List.of(columnIds));
}

class UserTableDraft implements Draft<UserTableRec> {
  UserTableDraft(this.name, this.columnIds);
  String name;
  List<int> columnIds;
  @override
  UserTableRec toRec(int id) => UserTableRec(id, name: name, columnIds: columnIds);
}

class UserRowRec implements Identifiable {
  const UserRowRec(
    this.id, {
    required this.tableId,
    this.eventId,
    this.timestampMillis,
    required this.values,
  });
  @override
  final int id;
  final int tableId;
  final int? eventId;
  final int? timestampMillis;
  final List<int?> values; // parallel to table.columnIds
  @override
  UserRowDraft toDraft() => UserRowDraft(
    tableId,
    eventId: eventId,
    timestampMillis: timestampMillis,
    values: List.of(values),
  );
}

class UserRowDraft implements Draft<UserRowRec> {
  UserRowDraft(this.tableId, {this.eventId, this.timestampMillis, this.values = const []});
  int tableId;
  int? eventId;
  int? timestampMillis;
  List<int?> values;
  @override
  UserRowRec toRec(int id) => UserRowRec(
    id,
    tableId: tableId,
    eventId: eventId,
    timestampMillis: timestampMillis,
    values: values,
  );
}

// ============ BLOB DEFINITIONS ============

/// A field's type. Sealed so every consumer (UI renderer, validator,
/// JSON codec) gets exhaustiveness-checked switches
sealed class BlobFieldType {
  const BlobFieldType();

  factory BlobFieldType.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String;
    return switch (kind) {
      'int' => const DInt(),
      'decimal' => const DDecimal(),
      'bool' => const DBool(),
      'enum' => DEnum(json['group'] as String),
      // Reserved for later
      // 'list' => DList(FieldSpec.fromJson(json['element'])),
      'tuple' => DTuple([for (final e in json['elements']) BlobFieldSpec.fromJson(e)]),
      _ => throw FormatException('Unknown field kind: $kind'),
    };
  }

  Map<String, dynamic> toJson();
}

/// Represents a scalar integer field
final class DInt extends BlobFieldType {
  const DInt();
  @override
  Map<String, dynamic> toJson() => {'kind': 'int'};
}

/// Represents a scalar decimal field
final class DDecimal extends BlobFieldType {
  const DDecimal();
  @override
  Map<String, dynamic> toJson() => {'kind': 'decimal'};
}

/// Represents a plain boolean field
final class DBool extends BlobFieldType {
  const DBool();
  @override
  Map<String, dynamic> toJson() => {'kind': 'bool'};
}

/// Represents a single timestamp
final class DTimestamp extends BlobFieldType {
  const DTimestamp();
  @override
  Map<String, dynamic> toJson() => {'kind': 'timestamp'};
}

/// Represents a duration of time
final class DDuration extends BlobFieldType {
  const DDuration();
  @override
  Map<String, dynamic> toJson() => {'kind': 'timestamp'};
}

/// References a named group of user-defined enum values (e.g. "food").
/// The group itself lives in its own table,
/// this just stores which group a field draws from.
final class DEnum extends BlobFieldType {
  const DEnum(this.group);
  final String group;
  @override
  Map<String, dynamic> toJson() => {'kind': 'enum', 'group': group};
}

/// Represents a fixed array of sub-fields.
final class DTuple extends BlobFieldType {
  const DTuple(this.elements);
  final List<BlobFieldSpec> elements;
  @override
  Map<String, dynamic> toJson() => {'kind': 'tuple', 'elements': elements.map((e) => e.type.toJson())};
}

/// Specifies a field with its type and nullability
class BlobFieldSpec {
  const BlobFieldSpec(this.type, {this.nullable = false});
  final BlobFieldType type;
  final bool nullable;

  factory BlobFieldSpec.fromJson(Map<String, dynamic> json) => BlobFieldSpec(
    BlobFieldType.fromJson(json['type'] as Map<String, dynamic>),
    nullable: json['nullable'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'type': type.toJson(),
    if (nullable) 'nullable': true,
  };
}

class BlobSchemaDraft implements Draft<BlobSchemaRec> {
  BlobSchemaDraft(
    this.name, {
    required this.fields,
  });
  String name;
  final Map<String, BlobFieldSpec> fields;

  @override
  BlobSchemaRec toRec(int id) {
    return BlobSchemaRec(id, name: name, fields: Map.from(fields));
  }

  @override
  bool operator ==(Object other) {
    return other is BlobSchemaDraft && other.name == name && mapEquals(other.fields, fields);
  }

  @override
  // TODO: implement hashCode
  int get hashCode => Object.hash(name, fields);
}

class BlobSchemaRec implements Identifiable {
  const BlobSchemaRec(
    this.id, {
    required this.name,
    required this.fields,
  });
  @override
  final int id;
  final String name;
  final Map<String, BlobFieldSpec> fields;

  @override
  BlobSchemaDraft toDraft() => BlobSchemaDraft(
    name,
    fields: Map.from(fields),
  );
}

// ============ BLOB DATA (each record is an instance of these...) ============

class UserBlobRec implements Identifiable {
  const UserBlobRec(
    this.id, {
    required this.schemaId,
    this.eventId,
    required this.values,
  });
  @override
  final int id;
  final int schemaId;
  final int? eventId;
  final Map<String, dynamic> values;
  @override
  UserBlobDraft toDraft() => UserBlobDraft(
    schemaId,
    eventId: eventId,
    values: values,
  );
}

class UserBlobDraft extends Draft<UserBlobRec> {
  UserBlobDraft(
    this.schemaId, {
    this.eventId,
    Map<String, dynamic>? values,
  }) : values = values ?? {};

  final int schemaId;
  int? eventId;
  Map<String, dynamic> values;

  @override
  bool operator ==(Object other) =>
      other is UserBlobDraft &&
      schemaId == other.schemaId &&
      eventId == other.eventId &&
      const DeepCollectionEquality().equals(values, other.values);

  @override
  int get hashCode => Object.hash(
    schemaId,
    eventId,
    const DeepCollectionEquality().hash(values),
  );

  @override
  UserBlobRec toRec(int id) => UserBlobRec(id, schemaId: schemaId, eventId: eventId, values: values);
}
