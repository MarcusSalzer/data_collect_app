import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/users_schema.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
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

  Map<String, dynamic> toJson() => {'id': id, "name": name};
}

class UserEnumValueDraft implements Draft<UserEnumValueRec> {
  UserEnumValueDraft(this.enumId, this.name);
  int enumId;
  String name;
  @override
  UserEnumValueRec toRec(int id) => UserEnumValueRec(id, enumId: enumId, name: name);
}

/// Data object to hold a enum and its values
class UserEnumHydrated extends UserEnumRec {
  final List<UserEnumValueRec> values;

  UserEnumHydrated(super.id, this.values, {required super.name});

  Map<String, dynamic> toJson() => {'id': id, "name": name, "values": values};
}

// ============ USER TABLE THINGS (EXPERIMENTAL) ============

@Deprecated("blobs")
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

@Deprecated("blobs")
class UserColumnDraft implements Draft<UserColumnRec> {
  UserColumnDraft(this.name, this.dtype, {this.enumId});
  String name;
  DType dtype;
  int? enumId;
  @override
  UserColumnRec toRec(int id) => UserColumnRec(id, name: name, dtype: dtype, enumId: enumId);
}

@Deprecated("blobs")
class UserTableRec implements Identifiable {
  const UserTableRec(this.id, {required this.name, required this.columnIds});
  @override
  final int id;
  final String name;
  final List<int> columnIds;
  @override
  UserTableDraft toDraft() => UserTableDraft(name, List.of(columnIds));
}

@Deprecated("blobs")
class UserTableDraft implements Draft<UserTableRec> {
  UserTableDraft(this.name, this.columnIds);
  String name;
  List<int> columnIds;
  @override
  UserTableRec toRec(int id) => UserTableRec(id, name: name, columnIds: columnIds);
}

@Deprecated("blobs")
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

@Deprecated("blobs")
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
      // 'timestamp' => const DTimestamp(),
      'duration' => const DDuration(),
      'enum' => DEnum(json['group'] as String),
      'tuple' => DTuple([for (final e in json['elements']) BlobFieldSpec.fromJson(e)]),
      _ => throw FormatException('Unknown field kind: $kind'),
    };
  }

  Map<String, dynamic> toJson();

  /// Override this with runtime type validation
  bool validate(Object value);

  /// Default, display the type only
  @override
  String toString() {
    return runtimeType.toString();
  }
}

/// Represents a scalar integer field
final class DInt extends BlobFieldType {
  // IDEA: Maybe support min/max?
  final int? min;
  final int? max;

  const DInt({this.min, this.max});
  @override
  Map<String, dynamic> toJson() {
    final j = <String, dynamic>{"kind": "int"};

    if (min != null) {
      j["min"] = min;
    }
    if (max != null) {
      j["max"] = max;
    }
    return j;
  }

  @override
  bool validate(Object value) => value is int;
}

/// Represents a scalar decimal field
final class DDecimal extends BlobFieldType {
  const DDecimal();
  @override
  Map<String, dynamic> toJson() => {'kind': 'decimal'};

  @override
  bool validate(Object value) => value is double;
}

/// Represents a scalar decimal field
final class DText extends BlobFieldType {
  const DText();
  @override
  Map<String, dynamic> toJson() => {'kind': 'text'};

  @override
  bool validate(Object value) => value is String;
}

/// Represents a plain boolean field
final class DBool extends BlobFieldType {
  const DBool();
  @override
  Map<String, dynamic> toJson() => {'kind': 'bool'};

  @override
  bool validate(Object value) => value is bool;
}

/// Represents a single timestamp (milliseconds) OR make it more flexible?! week/day/hour/minute/ +TZ?
// final class DTimestamp extends BlobFieldType {
//   const DTimestamp();
//   @override
//   Map<String, dynamic> toJson() => {'kind': 'timestamp'};

//   @override
//   bool validate(Object value) => value is ...;
// }

///
// final class DDate extends BlobFieldType {
//   @override
//   Map<String, dynamic> toJson() => {'kind': 'date'};
// }

/// Represents a duration of time (milliseconds)
final class DDuration extends BlobFieldType {
  const DDuration();
  @override
  Map<String, dynamic> toJson() => {'kind': 'duration'};
  @override
  bool validate(Object value) => value is Duration;
}

/// References a named group of user-defined enum values (e.g. "food").
/// The group itself lives in its own table,
/// this just stores which group a field draws from.
final class DEnum extends BlobFieldType {
  const DEnum(this.group);
  final String group;
  @override
  Map<String, dynamic> toJson() => {'kind': 'enum', 'group': group};

  @override
  String toString() => "$runtimeType($group)";

  @override
  bool validate(Object value) => value is String;
}

/// Represents a fixed array of sub-fields.
final class DTuple extends BlobFieldType {
  const DTuple(this.elements);
  final List<BlobFieldSpec> elements;
  @override
  Map<String, dynamic> toJson() => {'kind': 'tuple', 'elements': elements.map((e) => e.type.toJson())};
  @override
  bool validate(Object value) => value is List;
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

  @override
  String toString() {
    return "($type, ${nullable ? 'optional' : 'required'})";
  }

  @override
  int get hashCode => DeepCollectionEquality().hash(toJson());

  @override
  bool operator ==(Object other) {
    return other is BlobFieldSpec && DeepCollectionEquality().equals(other.toJson(), toJson());
  }
}

class BlobSchemaDraft implements Draft<BlobSchemaRec> {
  BlobSchemaDraft(
    this.name, {
    required this.fields,
    this.evtLink,
  });
  String name;
  final Map<String, BlobFieldSpec> fields;
  EvtLinkSpec? evtLink; // Should this schema include a event-id field?

  @override
  BlobSchemaRec toRec(int id) {
    return BlobSchemaRec(id, name: name, fields: Map.from(fields), evtLink: evtLink);
  }

  @override
  bool operator ==(Object other) {
    return other is BlobSchemaDraft &&
        other.name == name &&
        DeepCollectionEquality().equals(other.fields, fields) &&
        other.evtLink == evtLink;
  }

  @override
  int get hashCode => Object.hash(name, fields);
  @override
  String toString() {
    return "$name: $fields";
  }
}

/// Defines how a BlobSchema relates to EvtTypes
class EvtLinkSpec {
  final Set<int> typIds; // allowed typIds: empty means ALL.
  const EvtLinkSpec(this.typIds);

  /// Make an event link that accepts any avent type.
  EvtLinkSpec.allTypes() : this({});

  /// Does it relate to a single event type.
  bool get singleType => typIds.length == 1;

  bool acceptsEvtTyp(int evtTyp) => typIds.isEmpty || typIds.contains(evtTyp);

  @override
  String toString() {
    final desc = typIds.isEmpty ? "ANY" : typIds.toString();
    return "EvtLink ($desc)";
  }

  List<int> toList() => typIds.toList(growable: false);

  @override
  bool operator ==(Object other) => other is EvtLinkSpec && setEquals(other.typIds, typIds);

  @override
  int get hashCode => typIds.hashCode;
}

/// Stored schema definition
class BlobSchemaRec implements Identifiable {
  const BlobSchemaRec(this.id, {required this.name, required this.fields, this.evtLink});
  @override
  final int id;
  final String name;
  final Map<String, BlobFieldSpec> fields;
  final EvtLinkSpec? evtLink; // Should this schema include a event-id field?

  @override
  BlobSchemaDraft toDraft() => BlobSchemaDraft(name, fields: Map.from(fields), evtLink: evtLink);

  @override
  String toString() {
    return "$id, ${toDraft()}";
  }

  /// Complete JSON of the stored object
  Map<String, dynamic> toJson() => {"id": id, "name": name, "fields": fields};

  /// From json
  factory BlobSchemaRec.fromJson(Map<String, dynamic> j) {
    final id = int.parse(j["id"]);

    final fieldMap = j["fields"];
    if (fieldMap is! Map<String, dynamic>) {
      throw FormatException("j['fields'] should be a Map");
    }
    return BlobSchemaRec(
      id,
      name: j["name"],
      fields: {
        for (final e in fieldMap.entries) e.key: BlobFieldSpec.fromJson(e.value as Map<String, dynamic>),
      },
      evtLink: j["evtLink"] ?? false,
    );
  }

  /// Which enum-groups are used by this schema
  Set<String> usesEnums() => fields.values.map((f) => f.type).whereType<DEnum>().map((et) => et.group).toSet();
}

// ============ BLOB DATA (each record is an instance of these...) ============

/// Stored data, belongs to some schema.
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

  /// Complete JSON of the stored object
  Map<String, dynamic> toJson() => {"id": id, "schemaId": schemaId, "eventId": eventId, "values": values};

  @override
  String toString() {
    return "$id, s:$schemaId, e:$eventId, $values";
  }
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
