import 'dart:io';

import 'package:data_app2/app_state.dart';
import 'package:data_app2/importv2.dart';
import 'package:data_app2/raw_data_import_manager.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum ImportStatus { scanning, idle, preParsing, importing }

/// Handles UI state during import and calls the ImportManager methods.
class ImportRawVm extends ChangeNotifier {
  final AppState app;
  final RawDataImportManager manager;
  Directory folder;
  ImportRawVm(this.app, this.folder) : manager = RawDataImportManager(app.db, app.updatePrefs) {
    // start scan immediately
    manager.scan(folder).then((_) {
      status = ImportStatus.idle;
      notifyListeners();
    });
  }

  // --- state ---
  ImportStatus status = ImportStatus.scanning;
  ImportResult? res;
  String? errorMsg;

  Future<void> parse() async {
    status = ImportStatus.preParsing;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 600));
    await manager.preParse();

    status = ImportStatus.idle;
    notifyListeners();
  }

  Future<void> import() async {
    status = ImportStatus.importing;
    notifyListeners();
    await Future.delayed(Duration(milliseconds: 600));

    // Full parse & DB import. Many things can fail
    try {
      res = await manager.import();
    } catch (e) {
      errorMsg = e.toString();
      notifyListeners();
    }

    // reload caches
    app.locationManager.reloadFromModels(await app.db.locations.all());
    app.evtTypeManager.reloadFromModels(
      await app.db.evtTypes.all(),
      await app.db.evtCats.all(),
    );

    status = ImportStatus.idle;
    notifyListeners();
  }
}

/// Screen for importing a complete database from multiple files.
class ImportRawScreen extends StatelessWidget {
  final Directory folder;

  const ImportRawScreen(this.folder, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Import all data"),
      ),
      body: ChangeNotifierProvider<ImportRawVm>(
        create: (context) => ImportRawVm(context.read<AppState>(), folder),
        builder: (context, _) {
          final vm = context.watch<ImportRawVm>();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vm.folder.path,
                    style: TextStyle(fontFamily: "monospace"),
                  ),
                  Builder(
                    builder: (context) {
                      if (vm.errorMsg case String err) {
                        return Center(
                          child: Text(err),
                        );
                      }
                      return switch (vm.status) {
                        ImportStatus.scanning => Text("Scanning..."),
                        ImportStatus.idle => Builder(
                          builder: (context) {
                            if (vm.res case ImportResult res) {
                              return _SummaryDisplay(res);
                            }
                            return _ScanResultDisplay(vm.manager.candidates);
                          },
                        ),
                        ImportStatus.preParsing => Text("Parsing..."),
                        ImportStatus.importing => Text("Importing..."),
                      };
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryDisplay extends StatelessWidget {
  final ImportResult res;

  const _SummaryDisplay(this.res);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: res.counts.entries
          .map(
            (e) => Row(
              mainAxisSize: MainAxisSize.max,
              children: [Text(e.key.name), Text(e.value.toString())],
            ),
          )
          .toList(),
    );
  }
}

class _CandidateDisplay extends StatelessWidget {
  final RawDataFile c;

  const _CandidateDisplay(this.c);
  @override
  Widget build(BuildContext context) {
    final thm = Theme.of(context);
    return Container(
      color: thm.colorScheme.primaryContainer,
      padding: EdgeInsets.all(4),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text("${c.file.basename} (${c.sizeBytes ~/ 1024} kiB)"),
                Text(
                  c.role.name,
                  style: TextStyle(color: c.role == ImportFileRole.unknown ? Colors.red : null),
                ),
              ],
            ),
          ),
          if (c.fields case Set<String> f)
            Text(
              f.toString(),
              style: TextStyle(color: thm.colorScheme.onPrimaryContainer),
            ),
          if (c.nRecords case int n) Text("$n record${n != 1 ? 's' : ''}"),
          if (c.missingFields?.isNotEmpty ?? false)
            Text(
              "Missing: ${c.missingFields}",
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}

class _ScanResultDisplay extends StatelessWidget {
  final List<RawDataFile> candidates;

  const _ScanResultDisplay(this.candidates);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ImportRawVm>();
    if (candidates.isEmpty) {
      return Center(
        child: Text("No files found"),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: candidates
              .map(
                (c) => _CandidateDisplay(c),
              )
              .toList(),
        ),
        Center(
          child: vm.manager.canImportFileCount > 0
              ? TextButton(
                  onPressed: vm.import,
                  child: Text("Confirm import (${vm.manager.canImportFileCount} files)"),
                )
              : TextButton(
                  onPressed: vm.parse,
                  child: Text("Parse data"),
                ),
        ),
      ],
    );
  }
}
