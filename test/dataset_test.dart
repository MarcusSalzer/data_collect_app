import 'package:data_collector_app/data_util.dart';
import 'package:test/test.dart';

void main() {
  test("dataset to map", () {
    final m = <String, dynamic>{
      "name": "testet123",
      "schema": {"a": "numeric  "},
      "length": 3,
    };
    final ds = Dataset(m["name"], m["schema"], m["length"]);

    expect(ds.toMap(), m);
  });
}
