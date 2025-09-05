import 'package:data_app2/user_events.dart';

/// Get total time for each event type.
List<MapEntry<int, Duration>> timePerEvent(Iterable<EvtRec> events,
    {int? limit}) {
  final Map<int, int> result = {};
  for (final evt in events) {
    // Compute durations from UTC TIMES. (in seconds)
    final eSeconds = evt.duration?.inSeconds;
    if (eSeconds != null) {
      result[evt.typeId] = (result[evt.typeId] ?? 0) + eSeconds;
    }
  }
  final resList = result.entries
      .map((e) => MapEntry(e.key, Duration(seconds: e.value)))
      .toList();
  resList.sort((a, b) => b.value.compareTo(a.value));

  if (limit == null || limit >= resList.length) {
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
Duration totalEventTime(List<EvtRec> evts) {
  return evts.fold(Duration.zero, (p, e) {
    final eDur = e.duration;
    if (eDur != null) {
      return p + eDur;
    }
    return p;
  });
}
