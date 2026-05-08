import 'dart:io';

import 'package:data_app2/style.dart';
import 'package:data_app2/users_schema.dart';
import 'package:data_app2/util/enums.dart';
import 'package:isar_community/isar.dart';

// important: this file will contain Isar's generated code.
part 'isar_models.g.dart';

/// A singleton Isar object holding app prefs
@collection
class Preferences {
  Id id = 0; // a single instance.
  @Enumerated(EnumType.ordinal)
  ColorSchemeMode colorSchemeMode;
  // input normalization preferences
  bool autoLowerCase;

  // logging
  @Enumerated(EnumType.ordinal)
  LogLevel logLevel;

  // For various search fields
  @Enumerated(EnumType.ordinal)
  TextSearchMode textSearchMode;

  Preferences(this.colorSchemeMode, this.autoLowerCase, this.logLevel, this.textSearchMode);
}

/// A timed event
/// Store the time both in local and utc to avoid ambiguities when traveling or DST
@collection
class Event {
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

  Event({
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
class EventType {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String name;
  @Enumerated(EnumType.ordinal)
  int categoryId;

  EventType(this.name, [this.categoryId = 1]);
}

/// A category of event types
@collection
class EventCategory {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String name;
  int colorArgb32;
  EventCategory(this.name, [this.colorArgb32 = 0]);
}

@collection
class Location {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String name;

  double lat;
  double lng;

  Location(this.name, this.lat, this.lng);
}

// ================== UserSchemas ==================

/// A user-defined enum group (e.g. "food", "mood")
@collection
class UserEnum {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String name;

  UserEnum(this.name);
}

/// A value within a user-defined enum (e.g. "pizza", "happy")
@collection
class UserEnumValue {
  Id id = Isar.autoIncrement;

  @Index()
  int enumId;

  @Index(composite: [CompositeIndex('enumId')], unique: true)
  String name;

  UserEnumValue(this.enumId, this.name);
}

/// A column definition (e.g. "distance", DType.dFloat)
@collection
class UserColumn {
  Id id = Isar.autoIncrement;

  String name;

  @Enumerated(EnumType.ordinal)
  DType dtype;

  /// Only set when dtype == DType.dEnum
  int? enumId;

  UserColumn(this.name, this.dtype, {this.enumId});
}

/// A user-defined table (e.g. "Runs", "Meals")
@collection
class UserTable {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String name;

  /// Ordered list of UserColumn IDs
  List<int> columnIds;

  UserTable(this.name, this.columnIds);
}

/// A row in a user-defined table
@collection
class UserRow {
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

  UserRow({
    required this.tableId,
    this.eventId,
    this.timestampMillis,
    this.values = const [],
  });
}

/// Initialize DB connection
Future<Isar> initIsar(Directory dir) async {
  final isar = await Isar.open(
    [
      EventSchema,
      EventTypeSchema,
      EventCategorySchema,
      LocationSchema,
      UserEnumSchema,
      UserEnumValueSchema,
      UserRowSchema,
      UserColumnSchema,
      UserTableSchema,
    ],
    name: "data_app_db",
    directory: dir.path,
  );
  return isar;
}
