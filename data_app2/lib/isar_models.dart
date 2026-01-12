import 'package:data_app2/style.dart';
import 'package:data_app2/util/colors.dart';
import 'package:data_app2/util/enums.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

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
  // where to export data?

  // logging
  @Enumerated(EnumType.ordinal)
  LogLevel logLevel;

  // For various search fields
  @Enumerated(EnumType.ordinal)
  TextSearchMode textSearchMode;

  Preferences(
    this.colorSchemeMode,
    this.autoLowerCase,
    this.logLevel,
    this.textSearchMode,
  );
}

/// A timed event
/// Store the time both in local and utc to avoid ambiguities when traveling or DST
@collection
class Event {
  Id id = Isar.autoIncrement;
  int typeId;

  // start and end times are optional
  @Index()
  int? startLocalMillis;
  int? startUtcMillis;
  @Index()
  int? endLocalMillis;
  int? endUtcMillis;

  Event({
    required this.typeId,
    this.startLocalMillis,
    this.startUtcMillis,
    this.endLocalMillis,
    this.endUtcMillis,
  });
}

/// A type of event
@collection
class EventType {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String name;
  @Enumerated(EnumType.ordinal)
  ColorKey color;
  int? categoryId;

  EventType(this.name, [this.color = ColorKey.base, this.categoryId]);
}

/// A type of event
@collection
class EventCategory {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String name;

  EventCategory(this.name);
}

// USER-DEFINED TABULAR DATASETS

@collection
class UserTable {
  Id id = Isar.autoIncrement;
  String name;
  List<String> colNames;
  // the datatype for each column (enum for each column)
  @Enumerated(EnumType.ordinal)
  List<TabularType> schema;
  // optionally keep records at a fixed frequency
  @Enumerated(EnumType.ordinal)
  TableFreq frequency = TableFreq.free;

  UserTable(
    this.name,
    this.colNames,
    this.schema, {
    this.frequency = TableFreq.free,
  });
}

@collection
class UserRow {
  Id? id;
  // what table does the record belong to?
  int tableId;
  DateTime timestamp;
  // values for each column, decode according to the Table's schema
  List<int?> values;

  UserRow(this.tableId, this.timestamp, this.values, {this.id});
}

/// Initialize DB connection
Future<Isar> initIsar() async {
  // The applicationDocumentsdirectory is a safe choice, especially for Android.
  // on android the app might not be allowed to write to user facing folders.
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [
      PreferencesSchema,
      EventSchema,
      UserTableSchema,
      UserRowSchema,
      EventTypeSchema,
      EventCategorySchema,
    ],
    name: "data_app_db",
    directory: dir.path,
  );
  return isar;
}
