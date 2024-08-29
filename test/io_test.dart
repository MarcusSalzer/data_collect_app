import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:data_collector_app/utility/io_util.dart';

void main() {
  group('io_util', () {
    late File tempFile;

    setUp(() async {
      // Create a temporary directory and file
      final tempDir = Directory.systemTemp.createTempSync();
      tempFile = File(path.join(tempDir.path, 'test.csv'));

      // Write sample CSV data to the file
      await tempFile
          .writeAsString('name,age,city\nJohn,30,New York\nJane,25,London\n');
    });

    tearDown(() async {
      // Delete the temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('parses CSV file correctly', () async {
      final expectedRows = [
        ['name', 'age', 'city'],
        ['John', '30', 'New York'],
        ['Jane', '25', 'London'],
      ];

      final actualRows = <List<String>>[];

      await for (var row in streamCsv("test", tempFile.parent)) {
        actualRows.add(row);
      }

      expect(actualRows, equals(expectedRows));
    });
  });
}
