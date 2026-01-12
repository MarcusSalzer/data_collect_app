import 'dart:io';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/import/import_candidate_collection.dart';
import 'package:data_app2/style.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/view_models/import_folder_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Screen for the full workflow of importing a folder
class ImportFolderScreen extends StatelessWidget {
  final Directory _folder;

  const ImportFolderScreen(this._folder, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImportFolderVm(
        _folder,
        Provider.of<AppState>(context, listen: false),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Import folder')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<ImportFolderVm>(
            builder: (context, vm, _) {
              switch (vm.step) {
                case ImportStep.scanningFolder:
                  return _loading('Scanning folder…');

                case ImportStep.confirmFiles:
                  return _showCandidates(context, vm);

                case ImportStep.preparingModels:
                  return _loading('Preparing data…');

                case ImportStep.confirmImport:
                  return _confirmImport(context, vm);

                case ImportStep.importing:
                  return _loading('Importing…');

                case ImportStep.done:
                  return _done(context, vm.result);

                case ImportStep.error:
                  return _error(vm.error);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _showCandidates(BuildContext context, ImportFolderVm vm) {
    return Column(
      spacing: 12,
      children: [
        Text('Detected files', style: TextStyle(fontSize: 16)),
        Expanded(child: _candidateDisplay(vm.candidates)),
        _bottomBar(
          child: (vm.candidates.canImport)
              ? ElevatedButton(
                  onPressed: () => vm.prepareDomainModels(),
                  child: const Text('Parse data'),
                )
              : Text("Nothing to import"),
        ),
      ],
    );
  }

  Widget _candidateDisplay(ImportCandidateCollection cands) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CandidateGroup(name: "Events", candidates: cands.evtCands),
          CandidateGroup(name: "Event Types", candidates: cands.evtTypeCands),
          CandidateGroup(name: "Unknown", candidates: cands.unknownCands),
        ],
      ),
    );
  }

  Widget _confirmImport(BuildContext context, ImportFolderVm vm) {
    // return Column(
    //   children: [
    //     Text(
    //       'Data parsed successfully.\nReady to import.',
    //       style: TextStyle(fontSize: 16),
    //     ),
    //     Expanded(child: _candidateDisplay(vm.candidates)),
    //     OverlapOptionForm(vm),
    //     _bottomBar(
    //       child: ElevatedButton(
    //         onPressed: vm.importToDb,
    //         child: const Text('Import'),
    //       ),
    //     ),
    //   ],
    // );
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Data parsed successfully.',
                    style: TextStyle(fontSize: 16),
                  ),
                  Expanded(child: _candidateDisplay(vm.candidates)),
                ],
              ),
            ),
            _bottomBar(
              child: Column(
                spacing: 8,
                children: [
                  OverlapOptionSummary(vm),
                  ElevatedButton(
                    onPressed: vm.importToDb,
                    child: const Text('Import'),
                  ),
                ],
              ),
            ),
          ],
        ),
        OverlapOptionOverlay(vm),
      ],
    );
  }

  Widget _loading(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(text),
        ],
      ),
    );
  }

  Widget _done(BuildContext context, ImportResult? result) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          const Text('Import completed'),
          (result == null)
              ? Text("Error, no result")
              : _ImportResDisplay(result),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _error(String? msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          msg ?? 'Unknown error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _bottomBar({required Widget child}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _ImportResDisplay extends StatelessWidget {
  final ImportResult res;

  const _ImportResDisplay(this.res);
  @override
  Widget build(BuildContext context) {
    return Text("Imported: ${res.evtTypeCount} types, ${res.evtCount} events.");
  }
}

class CandidateGroup extends StatelessWidget {
  const CandidateGroup({
    super.key,
    required this.name,
    required this.candidates,
  });

  final String name;
  final List<CsvImportCandidate<Object?>> candidates;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          ...candidates.map((c) => CandidateTile(c)),
          if (candidates.isEmpty)
            Text("none", style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class CandidateTile extends StatelessWidget {
  const CandidateTile(this.cand, {super.key});

  final CsvImportCandidate<Object?> cand;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      Row(
        spacing: 6,
        children: [
          Text(cand.name, style: filePathText),
          Text("(${cand.size ~/ 1000} kB)"),
        ],
      ),
    ];
    // if there is more data loaded
    if (cand.summary case ImportCandidateSummary summary) {
      items.add(
        Row(
          spacing: 6,
          children: [
            Text("${summary.count} items."),
            Text(
              "${summary.idOverlapCount} existing Ids.",
              style: TextStyle(
                fontWeight: (summary.idOverlapCount > 0)
                    ? FontWeight.bold
                    : null,
              ),
            ),
          ],
        ),
      );
      // Optionally show dates
      final (ea, la) = (summary.earliest, summary.latest);
      if (ea != null || la != null) {
        items.add(Text("${Fmt.date(ea)} - ${Fmt.date(la)}"));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: items,
    );
  }
}

class OverlapOptionSummary extends StatelessWidget {
  final ImportFolderVm vm;

  const OverlapOptionSummary(this.vm, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Handling existing IDs'),
      subtitle: Text(vm.overlapPolicy.title),
      trailing: const Icon(Icons.expand_more),
      onTap: vm.toggleOverlapOptions,
    );
  }
}

class OverlapOptionOverlay extends StatelessWidget {
  final ImportFolderVm vm;

  const OverlapOptionOverlay(this.vm, {super.key});

  @override
  Widget build(BuildContext context) {
    if (!vm.showOverlapOptions) return const SizedBox.shrink();

    return SafeArea(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text(
                'Handling existing IDs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: vm.closeOverlapOptions,
              ),
            ),
            const Divider(),
            Expanded(child: OverlapOptionForm(vm)),
          ],
        ),
      ),
    );
  }
}

class OverlapOptionForm extends StatelessWidget {
  final ImportFolderVm vm;

  const OverlapOptionForm(this.vm, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RadioGroup<ImportOverlapPolicy>(
          groupValue: vm.overlapPolicy,
          onChanged: (p) => vm.setOverlapPolicy(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'When imported data contains existing IDs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...ImportOverlapPolicy.values.map(
                (policy) => RadioListTile<ImportOverlapPolicy>(
                  value: policy,
                  title: Text(policy.title),
                  subtitle: Text(policy.description),
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
