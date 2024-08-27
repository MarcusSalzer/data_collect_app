import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

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

/// stream splitted lines from '[name].csv' in data folder
Stream<List<String>> streamCsv({String? name, String? filePath}) async* {
  // get file to load
  late final File file;
  if (name != null) {
    file = File(p.join(
      (await FolderHelper.getDataDir()).path,
      "$name.csv",
    ));
  } else if (filePath != null) {
    file = File(filePath);
  } else {
    throw ArgumentError("provide name or path");
  }
  final stream = file.openRead();

  final lines = stream
      .transform(utf8.decoder) // Decode the bytes into a string
      .transform(const LineSplitter()); // Split the string into lines

  // yield lists of values (strings)
  await for (var line in lines) {
    yield line.split(',');
  }
}

Future<void> writeCsv(
  Iterable<String> lines, {
  String? name,
  String? filePath,
}) async {
  // get file to load
  late final File file;
  if (name != null) {
    file = File(p.join(
      (await FolderHelper.getDataDir()).path,
      "$name.csv",
    ));
  } else if (filePath != null) {
    file = File(filePath);
  } else {
    throw ArgumentError("provide name or path");
  }
  // Open the file for writing (overwriting if it already exists)
  final sink = file.openWrite();

  try {
    for (var line in lines) {
      sink.writeln(line); // Write each line with a newline at the end
    }
  } finally {
    // Close the sink to ensure all data is flushed to the file
    await sink.close();
  }
}

/// Copy a CSV file inside the data-directory.
Future<void> copyDataFile(String nameOld, String nameNew) async {
  final dir = await FolderHelper.getDataDir();

  File fileOld = File(p.join(dir.path, "$nameOld.csv"));
  File fileNew = File(p.join(dir.path, "$nameNew.csv"));

  await fileOld.copy(fileNew.path);
}

/// moves a CSV file to the trash directory
Future<void> moveDataToTrash(String name) async {
  var dir = await FolderHelper.getDataDir();
  var file = File(p.join(dir.path, "$name.csv"));

  // move file if exists
  if (await file.exists()) {
    var dirTrash = Directory(p.join(dir.path, "trash"));
    await dirTrash.create();
    await file.rename(p.join(dir.path, "trash", "$name.csv"));
  }
}
