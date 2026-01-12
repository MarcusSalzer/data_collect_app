// Generate dummy data with recent timestamps.

import 'dart:math';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/user_events.dart';

const evtSamples = [
  (name: "work", time: Duration(minutes: 75)),
  (name: "work", time: Duration(minutes: 102)),
  (name: "work", time: Duration(minutes: 75)),
  (name: "work", time: Duration(minutes: 75)),
  (name: "study", time: Duration(minutes: 45)),
  (name: "study", time: Duration(minutes: 45)),
  (name: "commute", time: Duration(minutes: 16)),
  (name: "commute", time: Duration(minutes: 16)),
  (name: "walk", time: Duration(minutes: 11)),
  (name: "walk", time: Duration(minutes: 11)),
  (name: "walk", time: Duration(minutes: 11)),
  (name: "bike", time: Duration(minutes: 52)),
  (name: "gym", time: Duration(minutes: 44)),
];

const nDays = 7;
const nPerDay = 7;
const durNoise = 15; // minutes

Future<Iterable<EvtRec>> dummyEvents(AppState app) async {
  final recs = <EvtRec>[];
  for (var day = 0; day < nDays; day++) {
    var pos = DateTime.now().subtract(Duration(days: day));
    final eIdxDay = randomSample(evtSamples.length, nPerDay);

    // add a few events for this day:
    for (var k in eIdxDay) {
      final ev = evtSamples[k];
      // add some noise to duration
      final noise = (Random().nextDouble() - 0.5) * durNoise;
      final dur = ev.time + Duration(minutes: noise.round());
      final end = pos;
      final start = pos.subtract(dur);
      pos = pos.subtract(dur);
      final name = ev.name;

      final r = EvtRec.inCurrentTZ(
        id: null,
        typeId: await app.evtTypeManager.resolveOrCreate(name: name),
        start: start,
        end: end,
      );
      recs.add(r);
    }
  }

  return recs;
}

List<int> randomSample(int n, int k) {
  final rng = Random();
  final nums = <int>[];
  if (k > n) {
    throw ArgumentError("cannot sample more!");
  }
  while (nums.length < k) {
    final i = rng.nextInt(n);
    if (!nums.contains(i)) {
      nums.add(i);
    }
  }
  return nums;
}
