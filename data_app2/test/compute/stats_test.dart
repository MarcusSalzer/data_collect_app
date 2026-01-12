import 'package:data_app2/util/stats.dart';
import 'package:test/test.dart';

void main() {
  test('valueCounts simple', () {
    final vc = valueCounts([1, 2, -99, 2, 2, -99]);
    expect({1: 1, 2: 3, -99: 2}, vc);
  });

  test('histogram simple', () {
    // one value close to border
    final hd = histogram([0.0, .1, 0.2, 0.5000001, 0.12, 1.0], nBins: 2);
    // Check bins
    expect(hd.x, [0.25, 0.75]);

    // Check hist-values
    expect(hd.y, [4, 2]);
  });
}
