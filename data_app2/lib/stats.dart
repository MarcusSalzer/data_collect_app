// Statistics computations
import 'dart:math' as math;

extension AggInt on Iterable<int> {
  int get sum => fold(0, (a, b) => a + b);
}

extension AggDouble on Iterable<double> {
  double get sum => fold(0.0, (a, b) => a + b);
}

/// Aggregate iterables
extension Agg<T extends num> on Iterable<T> {
  T get min => reduce((p, c) => math.min(p, c));
  T get max => reduce((p, c) => math.max(p, c));
}

/// Cleanup iterable
extension Cleanup<T> on Iterable<T?> {
  /// return all non-null elments in iterable
  Iterable<T> get removeNulls => whereType<T>();
}

///Generate evenly spaced values
List<double> linspace(num start, num end, int count) {
  final step = (end - start) / count;
  return List.generate(count, (i) => start + step * i);
}

/// Compute histogram of numbers
///
/// ## returns
/// - bins
/// - hist
(List<double>, List<int>) histogram<T extends num>(Iterable<T> arr,
    {nBins = 10}) {
  final mini = arr.min;
  final maxi = arr.max;
  final bw = (maxi - mini) / nBins;
  final hist = List.filled(nBins, 0);
  final bins = linspace(mini, maxi, nBins);
  for (var v in arr) {
    // TODO FIX
    final binIdx = (v - mini) ~/ (bw + 0.0001);
    hist[binIdx]++;
  }

  return (bins, hist);
}

/// Count unique values
Map<T, int> valueCounts<T extends Comparable>(
  Iterable<T> arr, {
  Iterable<T>? keys,
  bool sorted = false,
}) {
  // map
  final counts = keys != null ? <T, int>{for (var k in keys) k: 0} : <T, int>{};

  for (var v in arr) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  if (sorted) {
    final entryList = counts.entries.toList();
    entryList.sort((e1, e2) => e1.key.compareTo(e2.key));
    return Map.fromEntries(entryList);
  } else {
    return counts;
  }
}
