import 'dart:io';

import 'package:flutter/material.dart';
import 'package:data_collector_app/utility/io_util.dart' show FolderHelper;

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

  Future<void> _clearPrefs() async {
    if (await FolderHelper.clearPrefs()) {
      setState(() {
        _dataDir = FolderHelper.getDataDir();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: _dataDir,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return TextButton.icon(
                      onPressed: _chooseFolder,
                      label: const Text("Choose data folder"),
                      icon: const Icon(Icons.folder),
                    );
                  }
                  return TextButton.icon(
                    onPressed: _chooseFolder,
                    label: Text("current folder: ${snapshot.data?.path}"),
                    icon: const Icon(Icons.folder),
                  );
                } else {
                  return const Text("...");
                }
              },
            ),
            const Divider(),
            TextButton.icon(
              onPressed: _clearPrefs,
              icon: const Icon(Icons.delete_forever),
              label: const Text("clear preferences"),
            ),
          ],
        ),
      ),
    );
  }
}
