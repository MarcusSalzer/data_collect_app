import 'package:data_app2/util/enums.dart';

/// Filter options by mapping and comparing to a query string.
/// NOTE: Case insensitive
Iterable<T> textSearchFilter<T>(String query, Iterable<T> options, TextSearchMode mode, String Function(T) mapping) {
  query = query.toLowerCase();
  return switch (mode) {
    TextSearchMode.contains => options.where((o) => mapping(o).toLowerCase().contains(query)),
    TextSearchMode.starts => options.where((o) => mapping(o).toLowerCase().startsWith(query)),
    TextSearchMode.wordStarts => options.where(
      (o) => mapping(o).toLowerCase().startsWith(query) || mapping(o).toLowerCase().contains(" $query"), // space+query
    ),
  };
}
