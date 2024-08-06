import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

// TODO: make not static to keep dir in memory?
class FolderHelper {
  /// Select a folder for data and save in preferences
  static Future<String?> pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (selectedDirectory != null) {
      await prefs.setString('folderPath', selectedDirectory);
    }
    return selectedDirectory;
  }

  static Future<Directory> getDataDir() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var filePath = prefs.getString('folderPath');
    if (filePath != null) {
      return Directory(filePath);
    } else {
      throw const FileSystemException("no directory for data");
    }
  }

  static Future<bool> clearPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }
}

/// format and save data as CSV.
Future<void> saveDataCsv(Iterable<(DateTime, num)> data,
    {name = "data"}) async {
  var dir = await FolderHelper.getDataDir();
  var file = File(p.join(dir.path, "$name.csv"));

  var contents = data.map((row) => "${row.$1},${row.$2}").join("\n");

  // create and write to file
  if (!await file.exists()) {
    await file.create(recursive: true);
  }
  await file.writeAsString(contents);
}

/// load data from CSV
Future<List<(DateTime, num)>> loadDataCsv() async {
  var dir = await FolderHelper.getDataDir();
  var file = File(p.join(dir.path, "data.csv"));

  List<(DateTime, num)> data;

  if (await file.exists()) {
    var lines = await file.readAsLines();
    data = lines.map((line) {
      var values = line.split(",");
      var timestamp = DateTime.parse(values[0]);
      var number = num.parse(values[1]);
      return (timestamp, number);
    }).toList();
  } else {
    data = [];
  }
  return data;
}

Future<void> saveDataIndex(List datasets) async {
  throw UnimplementedError();
  // var dir = await FolderHelper.getDataDir();
  // var file = File(p.join(dir.path, "dataset_index.json"));

  // if (!await file.exists()) {
  //   await file.create(recursive: true);
  // }
}

Future<List> loadDataIndex() async {
  var dir = await FolderHelper.getDataDir();
  var file = File(p.join(dir.path, "dataset_index.json"));
  if (!await file.exists()) {
    await file.create(recursive: true);
  }
  List index = jsonDecode(await file.readAsString());

  return index;
}
