// Generate dummy data with recent timestamps.

import 'dart:math';

import 'package:data_app2/io.dart';

const evtTypes = [
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

Iterable<EvtRec> dummyEvents() {
  final recs = <EvtRec>[];
  for (var day = 0; day < nDays; day++) {
    var pos = DateTime.now().subtract(Duration(days: day));
    final eIdxDay = randomSample(evtTypes.length, nPerDay);
    for (var k in eIdxDay) {
      final ev = evtTypes[k];

      final end = pos;
      final start = pos.subtract(ev.time);
      pos = pos.subtract(ev.time);

      final r = EvtRec(null, ev.name, start, end);
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
