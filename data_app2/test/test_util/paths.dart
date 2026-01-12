// Temporary directories

import 'dart:io';

import 'package:path/path.dart' as p;

Future<Directory> getTmpDir() async {
  return await Directory.systemTemp.createTemp();
}

Future<File> getTmpFile([String name = "tmpfile"]) async {
  final dir = await Directory.systemTemp.createTemp();
  return File(p.join(dir.path, name));
}

Future<(Directory, Directory)> tmpDirWithSubdir() async {
  final dir = await getTmpDir();
  final userDir = Directory(p.join(dir.path, "user"));

  return (dir, userDir);
}
