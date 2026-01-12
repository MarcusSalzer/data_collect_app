import 'package:data_app2/io.dart';
import 'package:data_app2/screens/import_any_screen.dart';
import 'package:data_app2/screens/import_folder_screen.dart';
import 'package:flutter/material.dart';

Future<void> showImportSomethingDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      final theme = Theme.of(context);

      return SimpleDialog(
        title: Center(child: const Text('Import data')),
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 16),

        children: [
          Container(
            color: theme.colorScheme.primaryContainer,
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Text("Single file (CSV)"),
                TextButton(
                  onPressed: () async {
                    final path = await pickSingleFile();
                    if (path == null) {
                      return;
                    }

                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ImportAnyScreen(path),
                        ),
                      );
                    }
                  },
                  child: Text("Pick file"),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            color: theme.colorScheme.primaryContainer,
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Text("Folder, with full app data"),
                TextButton(
                  onPressed: () async {
                    final folder = await pickSingleFolder();
                    if (context.mounted && folder != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ImportFolderScreen(folder),
                        ),
                      );
                    }
                  },
                  child: Text("Pick folder"),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("cancel"),
          ),
        ],
      );
    },
  );
}
