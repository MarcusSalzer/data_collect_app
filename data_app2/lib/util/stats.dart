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
/// ## parameters
/// - arr: Iterable of numbers
/// - nBins: number of bin, null uses rule of thumb
///
/// ## returns
/// - binCenters
/// - hist
({List<double> x, List<int> y}) histogram<T extends num>(
  Iterable<T> arr, {
  int? nBins,
}) {
  if (arr.isEmpty) {
    return (x: [], y: []);
  }

  // auto bins
  nBins = math.sqrt(arr.length).toInt();

  final mini = arr.min;
  final maxi = arr.max;
  final bw = (maxi - mini) / nBins;
  final hist = List.filled(nBins, 0);
  final binCenters = linspace(mini + bw / 2, maxi + bw / 2, nBins);
  for (var v in arr) {
    // all should be inside
    final binIdx = (v - mini) ~/ (bw + 1e-9);
    hist[binIdx]++;
  }

  return (x: binCenters, y: hist);
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

/// reduce a list of map-entries to [n] first, + "other"
List<MapEntry<int, Duration>> groupLastEntries(
    Iterable<MapEntry<int, Duration>> entries,
    {int n = 10}) {
  var other = Duration.zero;
  for (var entry in entries.skip(n)) {
    other += entry.value;
  }
  final result = entries.take(n).toList();
  result.add(MapEntry(-1, other));
  return result;
}
