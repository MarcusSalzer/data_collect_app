import 'package:data_app2/db_service.dart' show Event;

/// Get total time for each event type.
List<MapEntry<int, Duration>> timePerEvent(Iterable<Event> events,
    {int? limit}) {
  final Map<int, Duration> result = {};
  for (final evt in events) {
    final start = evt.start;
    final end = evt.end;
    if (start != null && end != null) {
      result[evt.typeId] =
          (result[evt.typeId] ?? Duration.zero) + end.difference(start);
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

  if (restSum > Duration.zero) {
    keepList.add(MapEntry(-1, restSum));
  }

  return keepList;
}

/// get sum of event durations, for all events with start and end defined
Duration totalEventTime(List<Event> evts) {
  return evts.fold(Duration.zero, (p, e) {
    final es = e.start;
    final ee = e.end;
    if (es != null && ee != null) {
      final d = ee.difference(es);
      return p + d;
    }
    return p;
  });
}
