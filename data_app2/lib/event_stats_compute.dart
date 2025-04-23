import 'package:data_app2/db_service.dart' show Event;

/// Get total time for each event type.
List<MapEntry<String, Duration>> timePerEvent(Iterable<Event> events,
    {int? limit}) {
  final Map<String, Duration> result = {};
  for (final evt in events) {
    final start = evt.start;
    final end = evt.end;
    if (start != null && end != null) {
      result[evt.name] =
          (result[evt.name] ?? Duration.zero) + end.difference(start);
    }
  }
  final resList = result.entries.toList();
  resList.sort((a, b) => b.value.compareTo(a.value));

  if (limit == null || limit > resList.length) {
    return resList;
  }
  final keepList = resList.sublist(0, limit);
  // sum "other" events
  final restSum = resList.skip(limit).fold(
        Duration.zero,
        (p, entry) => p + entry.value,
      );
  keepList.add(MapEntry("other", restSum));

  return keepList;
}
