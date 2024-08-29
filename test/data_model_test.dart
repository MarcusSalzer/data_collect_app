import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:data_collector_app/utility/data_util.dart';
import 'package:path/path.dart' as p;

void main() {
  group('loading datasets', () {
    test("parses small json-like index", () async {
      var tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File(p.join(tempDir.path, "dataset_index.json"));
      tempFile.createSync();

      final dataIn = [
        {
          "name": "test1",
          "length": 37,
          "schema": {
            "abc": "numeric",
          }
        }
      ];
      tempFile.writeAsStringSync(jsonEncode(dataIn));

      final model = DataModel();
      await model.init(tempDir);

      final datasets = model.datasets;

      // assertions
      // expect(model.isLoading, false);
      expect(datasets.length, 1);
      expect(datasets[0].name, "test1");
      expect(datasets[0].length, 37);
      expect(datasets[0].schema, {"abc": "numeric"});
    });
  });
}
