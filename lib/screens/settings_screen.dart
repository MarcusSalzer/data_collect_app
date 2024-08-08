import 'dart:io';

import 'package:flutter/material.dart';
import 'package:data_collector_app/io_util.dart' show FolderHelper;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<Directory?> _dataDir;

  @override
  initState() {
    super.initState();
    _dataDir = FolderHelper.getDataDir();
  }

  Future<void> _chooseFolder() async {
    await FolderHelper.pickFolder();
    setState(() {
      _dataDir = FolderHelper.getDataDir();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("<SETTINGS>"),
        FutureBuilder(
          future: _dataDir,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return const Text("error getting folder.");
              }
              return Text("current folder: ${snapshot.data}");
            } else {
              return const Text("...");
            }
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text("choose folder"),
          onPressed: _chooseFolder,
        ),
        const Divider(),
        ElevatedButton.icon(
          onPressed: () async { 
            if (await FolderHelper.clearPrefs()) {
              setState(() {
                _dataDir = FolderHelper.getDataDir();
              });
              print("cleared prefs.");
            }
          },
          icon: const Icon(Icons.delete_forever),
          label: const Text("clear preferences"),
        ),
      ],
    );
  }
}

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text("Settings"));
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(56);
}