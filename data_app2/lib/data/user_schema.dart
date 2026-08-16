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

  Map<String, dynamic> toJson() => {"id": id, "enumId": enumId, "name": name};

  /// From json
  factory UserEnumValueRec.fromJson(Map<String, dynamic> j) {
    final id = j["id"];
    return UserEnumValueRec(id, enumId: j["enumId"], name: j["name"]);
  }
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

  UserEnumRec recOnly() => UserEnumRec(super.id, name: super.name);

  Map<String, dynamic> toJson() => {'id': id, "name": name, "values": values};

  /// From json
  factory UserEnumHydrated.fromJson(Map<String, dynamic> j) {
    final id = j["id"];

    if (id is! int) {
      throw FormatException("id must be an int");
    }

    final valList = j["values"];

    if (valList is! List) {
      throw FormatException("j['values'] should be a List. Got j.keys=${j.keys.toList()}, j['values']=${j['values']}");
    }
    for (var v in valList) {
      if (v is! Map<String, dynamic>) {
        throw FormatException("values should be maps, got '$v'");
      }
    }
    return UserEnumHydrated(id, valList.map((e) => UserEnumValueRec.fromJson(e)).toList(), name: j["name"]);
  }
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
sealed class BlobFieldType<T> {
  const BlobFieldType();

  // factory BlobFieldType.fromJson(Map<String, dynamic> json) {
  //   final kind = json['kind'] as String;
  //   return switch (kind) {
  //     'int' => const DInt(),
  //     'decimal' => const DDecimal(),
  //     'bool' => const DBool(),
  //     // 'timestamp' => const DTimestamp(),
  //     'duration' => const DDuration(),
  //     'enum' => DEnum(json['group'] as String),
  //     // 'tuple' => DTuple([for (final e in json['elements']) BlobFieldSpec.fromJson(e)]),
  //     'array' => DArray(BlobFieldSpec.fromJson(json['child'])),
  //     _ => throw FormatException('Unknown field kind: $kind'),
  //   };
  // }

  static BlobFieldType fromJson(Map<String, dynamic> json) {
    final kind = json['kind'];
    switch (kind) {
      case 'int':
        return const DInt();
      case 'decimal':
        return const DDecimal();
      case 'bool':
        return const DBool();
      case 'text':
        return const DText();
      // 'timestamp' => const DTimestamp(),
      case 'duration':
        return const DDuration();
      case 'enum':
        final g = json['group'];
        if (g is! String) {
          throw FormatException("needs an enum group name", json);
        }
        return DEnum(g);
      // 'tuple' => DTuple([for (final e in json['elements']) BlobFieldSpec.fromJson(e)]),
      case 'array':
        return DArray(BlobFieldSpec.fromJson(json['child']));

      default:
        throw FormatException('Unknown field kind: $kind');
    }
  }

  Map<String, dynamic> toJson();

  bool isValid(Object value) => value is T;

  /// Default, display the type only
  @override
  String toString() {
    return runtimeType.toString();
  }
}

/// Represents a scalar integer field
final class DInt extends BlobFieldType<int> {
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
}

/// Represents a scalar decimal field
final class DDecimal extends BlobFieldType<num> {
  const DDecimal();
  @override
  Map<String, dynamic> toJson() => {'kind': 'decimal'};
}

/// Represents a string of text
final class DText extends BlobFieldType<String> {
  const DText();
  @override
  Map<String, dynamic> toJson() => {'kind': 'text'};
}

/// Represents a plain boolean field
final class DBool extends BlobFieldType<bool> {
  const DBool();
  @override
  Map<String, dynamic> toJson() => {'kind': 'bool'};
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
final class DDuration extends BlobFieldType<int> {
  const DDuration();
  @override
  Map<String, dynamic> toJson() => {'kind': 'duration'};
}

/// References a named group of user-defined enum values (e.g. "food").
/// The group itself lives in its own table,
/// this just stores which group a field draws from.
final class DEnum extends BlobFieldType<String> {
  const DEnum(this.group);
  final String group;
  @override
  Map<String, dynamic> toJson() => {'kind': 'enum', 'group': group};

  @override
  String toString() => "$runtimeType($group)";

  @override
  bool isValid(Object value) => value is String;
}

/// Represents a fixed array of sub-fields. (Could be useful as item in list)
// final class DTuple extends BlobFieldType {
//   const DTuple(this.elements);
//   final List<BlobFieldSpec> elements;
//   @override
//   Map<String, dynamic> toJson() => {'kind': 'tuple', 'elements': elements.map((e) => e.type.toJson())};
//   @override
//   bool validate(Object value) => value is List;
// }

/// Represents a homogenous list of values.
final class DArray extends BlobFieldType<List> {
  const DArray(this.childType);
  final BlobFieldSpec childType;
  @override
  Map<String, dynamic> toJson() => {'kind': 'array', 'child': childType.toJson()};

  /// Recursive validation for list
  @override
  bool isValid(Object value) => value is List && value.fold(true, (p, c) => p && childType.isValid(c));
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

  bool isValid(Object? value) {
    if (value == null) {
      return nullable;
    }
    return type.isValid(value);
  }

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
    final id = j["id"];

    final evtLinkJson = j["evtLink"];

    if (evtLinkJson is! List?) {
      throw FormatException("evtLink must be a List or null, got '$evtLinkJson'");
    }
    EvtLinkSpec? el;

    if (evtLinkJson != null) {
      if (evtLinkJson.isEmpty) {
        el = EvtLinkSpec.allTypes();
      } else {
        if (evtLinkJson is! List<int>) {
          throw FormatException("evtLink items should be ints, got '$evtLinkJson'");
        }
        el = EvtLinkSpec(evtLinkJson.toSet());
      }
    }

    if (id is! int) {
      throw FormatException("id must be an int");
    }

    final fieldMap = j["fields"];
    if (fieldMap is! Map) {
      throw FormatException("j['fields'] should be a Map, got $fieldMap");
    }
    return BlobSchemaRec(
      id,
      name: j["name"],
      fields: {
        for (final e in fieldMap.entries) e.key: BlobFieldSpec.fromJson(e.value as Map<String, dynamic>),
      },
      evtLink: el,
    );
  }

  /// Which enum-groups are used by this schema
  Set<String> usesEnums() => fields.values.map((f) => f.type).whereType<DEnum>().map((et) => et.group).toSet();

  @override
  bool operator ==(Object other) => other is BlobSchemaRec && other.id == id && other.toDraft() == toDraft();

  @override
  int get hashCode => Object.hash(id, toDraft());
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
  // Values stored as a map with primitive values (string|int|float|bool) or a list of those
  // To get the exact meaning of a value, use the schema-object
  final Map<String, dynamic> values;
  @override
  UserBlobDraft toDraft() => UserBlobDraft(
    schemaId,
    eventId: eventId,
    values: values,
  );

  /// Complete JSON of the stored object
  Map<String, dynamic> toJson() => {"id": id, "schemaId": schemaId, "eventId": eventId, "values": values};

  /// From json
  factory UserBlobRec.fromJson(Map<String, dynamic> j) {
    final id = j["id"];
    final schemaId = j["schemaId"];
    final eventId = j["eventId"];

    if (id is! int) {
      throw FormatException("id must be an int");
    }

    if (schemaId is! int) {
      throw FormatException("schemaId must be an int");
    }

    if (eventId is! int?) {
      throw FormatException("eventId must be an int or null");
    }

    final valueMap = j["values"];
    if (valueMap is! Map<String, dynamic>) {
      throw FormatException("j['fields'] should be a Map");
    }
    return UserBlobRec(
      id,
      schemaId: schemaId,
      values: valueMap,
    );
  }
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
