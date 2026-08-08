import 'dart:io';

import 'package:data_app2/users_schema.dart';
import 'package:isar_community/isar.dart';

// important: this file will contain Isar's generated code.
part 'isar_models.g.dart';

/// A timed event
/// Store the time both in local and utc to avoid ambiguities when traveling or DST
@collection
class EventIsar {
  Id id = Isar.autoIncrement;
  @Index()
  int typeId;

  // start and end times are optional
  @Index()
  int? startLocalMillis;
  int? startUtcMillis;
  @Index()
  int? endLocalMillis;
  int? endUtcMillis;

  // optionally link to a location
  @Index()
  int? locationId;

  EventIsar({
    required this.typeId,
    this.startLocalMillis,
    this.startUtcMillis,
    this.endLocalMillis,
    this.endUtcMillis,
    this.locationId,
  });
}

/// A type of event
@collection
class EventTypeIsar {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String name;
  @Enumerated(EnumType.ordinal)
  int categoryId;

  EventTypeIsar(this.name, [this.categoryId = 1]);
}

/// A category of event types
@collection
class EventCategoryIsar {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String name;
  int colorArgb32;
  EventCategoryIsar(this.name, [this.colorArgb32 = 0]);
}

@collection
class LocationIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String name;

  double lat;
  double lng;

  LocationIsar(this.name, this.lat, this.lng);
}

// ================== UserSchemas ==================

/// A user-defined enum group (e.g. "food", "mood")
@collection
class UserEnumIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String name;

  UserEnumIsar(this.name);
}

/// A value within a user-defined enum (e.g. "pizza", "happy")
@collection
class UserEnumValueIsar {
  Id id = Isar.autoIncrement;

  @Index()
  int enumId;

  @Index(composite: [CompositeIndex('enumId')], unique: true)
  String name;

  UserEnumValueIsar(this.enumId, this.name);
}

/// A column definition (e.g. "distance", DType.dFloat)
@collection
class UserColumnIsar {
  Id id = Isar.autoIncrement;

  String name;

  @Enumerated(EnumType.ordinal)
  DType dtype;

  /// Only set when dtype == DType.dEnum
  int? enumId;

  UserColumnIsar(this.name, this.dtype, {this.enumId});
}

/// A user-defined table (e.g. "Runs", "Meals")
@collection
class UserTableIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String name;

  /// Ordered list of UserColumn IDs
  List<int> columnIds;

  UserTableIsar(this.name, this.columnIds);
}

/// A row in a user-defined table
@collection
class UserRowIsar {
  Id id = Isar.autoIncrement;

  @Index()
  int tableId;

  /// Promoted: FK to built-in event
  @Index()
  int? eventId;

  /// Promoted: standalone timestamp (for snapshots etc.)
  @Index()
  int? timestampMillis;

  /// columnId -> encoded int (floats as bits, enums as value ID, ints as-is)
  List<int?> values;

  UserRowIsar({
    required this.tableId,
    this.eventId,
    this.timestampMillis,
    this.values = const [],
  });
}

/// User defined schema for parsing/validating Blobs.
@collection
class UserBlobSchemaIsar {
  Id id = Isar.autoIncrement;
  @Index(unique: true) // Schemas mus have unique names.
  final String name;
  final String json;
  final bool evtLink;

  UserBlobSchemaIsar(this.name, {required this.json, required this.evtLink});
}

/// User defined Json data
@collection
class UserBlobIsar {
  Id id = Isar.autoIncrement;
  @Index() // Important, finding data for a schema.
  final int schemaId;
  @Index()
  final int? eventId;
  final String json;
  UserBlobIsar(
    this.json, {
    required this.schemaId,
    this.eventId,
  });
}

/// Which schemas should the database use.
const isarSchemas = [
  EventIsarSchema,
  EventTypeIsarSchema,
  EventCategoryIsarSchema,
  LocationIsarSchema,
  UserEnumIsarSchema,
  UserEnumValueIsarSchema,
  // UserRowSchema,
  // UserColumnSchema,
  // UserTableSchema,
  UserBlobSchemaIsarSchema,
  UserBlobIsarSchema,
];

/// Initialize DB connection
Future<Isar> initIsar(Directory dir) async {
  final isar = await Isar.open(isarSchemas, name: "data_app_db", directory: dir.path);
  return isar;
}
