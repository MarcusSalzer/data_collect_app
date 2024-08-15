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
      throw const FileSystemException("no directory for data"); //TODO catch this somewhere
    }
  }

  static Future<bool> clearPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }
}

/// Copy a CSV file inside the data-directory.
Future<void> copyDataFile(String nameOld, String nameNew) async {
  var dir = await FolderHelper.getDataDir();

  File fileOld = File(p.join(dir.path, "$nameOld.csv"));
  File fileNew = File(p.join(dir.path, "$nameNew.csv"));

  await fileOld.copy(fileNew.path);
}
