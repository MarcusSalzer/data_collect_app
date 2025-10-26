import 'package:data_app2/colors.dart';
import 'package:data_app2/csv/csv_schema.dart';
import 'package:data_app2/event_type_repository.dart';
import 'package:data_app2/local_datetime.dart';
import 'package:data_app2/user_events.dart';

abstract class CsvAdapter<T> {
  String sep;
  SchemaLevel schemaLevel;

  List<String> getCols();
  String toRow(T obj);
  T fromRow(String row);

  String get header {
    return getCols().join(sep);
  }

  CsvAdapter(this.sep, this.schemaLevel);

  /// Detect schema within the adapter
  SchemaLevel? detectCsvSchema(List<String> colNames) {
    for (final schema in SchemaLevel.values) {
      // Must contain all schema columns (order doesn’t matter)
      final colSet = getCols().toSet();
      if (colSet.difference(colNames.toSet()).isEmpty) {
        return schema;
      }
    }
    return null; // unknown schema
  }

  /// Parse many csv rows
  /// throws format exception on failed row
  List<T> parseRows(Iterable<String> rows) {
    final recs = <T>[];
    for (var (i, r) in rows.indexed) {
      try {
        recs.add(fromRow(r));
      } on FormatException catch (e) {
        // Specify where error occured
        throw FormatException(e.message, r, i);
      }
    }
    return recs;
  }
}

class EventCsvAdapter extends CsvAdapter<EvtRec> {
  EvtTypeRepository typeRepo;

  EventCsvAdapter(super.sep, super.schemaLevel, this.typeRepo);

  @override
  List<String> getCols() {
    return SchemaRegistry.forSchema(RecordKind.event, schemaLevel);
  }

  @override
  String toRow(EvtRec evt) {
    switch (schemaLevel) {
      case SchemaLevel.raw:
        return [
          evt.id,
          evt.typeId,
          evt.start?.utcMillis,
          evt.start?.localMillis,
          evt.end?.utcMillis,
          evt.end?.localMillis,
        ].join(sep);
      case SchemaLevel.human:
        var evtType = typeRepo.resolveById(evt.typeId);
        return [
          evt.id,
          evtType?.name,
          evt.start?.toUtcIso8601String(),
          evt.start?.toNaiveIso8601String(),
          evt.end?.toUtcIso8601String(),
          evt.end?.toNaiveIso8601String(),
        ].join(sep);
    }
  }

  @override
  EvtRec fromRow(String row) {
    final items = row.split(sep);
    final cols = getCols();
    if (items.length != cols.length) {
      throw FormatException(
          "got ${items.length} values (expected ${cols.length})");
    }
    switch (schemaLevel) {
      case SchemaLevel.raw:
        return EvtRec(
          id: int.parse(items[0]),
          typeId: int.parse(items[1]),
          start: LocalDateTime(
            int.parse(items[2]),
            int.parse(items[3]),
          ),
          end: LocalDateTime(
            int.parse(items[4]),
            int.parse(items[5]),
          ),
        );
      case SchemaLevel.human:
        var evtType = typeRepo.resolveByName(items[1]);

        if (evtType == null) {
          if (typeRepo is EvtTypeRepositoryPersist) {
            // make new type (needs ASYNC)??
            // persist new type
            // use new type
          } else {
            throw Exception("Cannot make new type without DB access");
          }
        }
        // TODO: Handle this case.
        throw UnimplementedError("cannot parse Human schema");
    }
  }
}

class EventTypeCsvAdapter extends CsvAdapter<EvtTypeRec> {
  EventTypeCsvAdapter(super.sep, super.schemaLevel);

  @override
  List<String> getCols() {
    return SchemaRegistry.forSchema(RecordKind.eventType, schemaLevel);
  }

  @override
  String toRow(EvtTypeRec rec) {
    switch (schemaLevel) {
      case SchemaLevel.raw:
        return [
          rec.id,
          rec.name,
          rec.color.index,
          // rec.categoryId,
        ].join(sep);

      case SchemaLevel.human:
        return [
          rec.id,
          rec.name,
          rec.color.name,
          // rec.categoryId,
        ].join(sep);
    }
  }

  @override
  EvtTypeRec fromRow(String row) {
    final items = row.split(sep);
    final cols = getCols();
    if (items.length != cols.length) {
      throw FormatException(
          "got ${items.length} values (expected ${cols.length})");
    }
    switch (schemaLevel) {
      case SchemaLevel.raw:
        return EvtTypeRec(
          id: int.parse(items[0]),
          name: items[1],
          color: ColorKey.values[int.parse(items[2])],
        );
      case SchemaLevel.human:
        // TODO: Handle this case.
        throw UnimplementedError("cannot parse Human schema");
    }
  }
}

/// A more informative exception for CSV parsing.
class CsvParseFormatException extends FormatException {
  final int rowIndex;
  final FormatException inner;
  final StackTrace innerStackTrace;

  CsvParseFormatException(
    super.message,
    super.source,
    this.rowIndex,
    this.inner,
    this.innerStackTrace,
  );
}
