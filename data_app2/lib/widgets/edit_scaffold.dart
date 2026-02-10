import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';

/// THe most important UI elements for a edit screen
/// Supports actions
class EditScaffoldSimple extends StatelessWidget {
  const EditScaffoldSimple({
    super.key,
    required this.title,
    required this.body,
    required this.saveAction,
    this.dismissError,
    this.deleteAction,
    this.errMsg,
    required this.isDirty,
  });

  final Future<bool> Function()? deleteAction;
  final Future<bool> Function() saveAction;
  final VoidCallback? dismissError;
  final String title;
  final String? errMsg;
  final bool isDirty;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, Object? res) async {
        if (didPop || !isDirty) return;

        if ((await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => ConfirmDialog(
                    title: "Discard changes?",
                    action: () {
                      Navigator.pop(dialogContext, true);
                    },
                    actionName: "discard",
                  ),
                ) ??
                false) &&
            context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("$title${isDirty ? " *" : ""}"),
          actions: [
            if (deleteAction != null)
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => ConfirmDialog(
                      title: "Are you sure?",
                      action: () async {
                        final cb = deleteAction;
                        if (cb == null) {
                          return;
                        }
                        final succ = await cb();

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                        if (context.mounted && succ) {
                          Navigator.of(context).pop("deleted");
                          simpleSnack(context, "Deleted");
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (errMsg case String msg)
                MaterialBanner(
                  content: Text(msg),
                  actions: [
                    if (dismissError != null) TextButton(onPressed: dismissError, child: const Text("Dismiss")),
                  ],
                ),
              Expanded(child: body),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 36,
                  // always show sizedbox, prevents shift when button appears
                  child: (isDirty)
                      ? SafeArea(
                          child: TextButton(
                            onPressed: () async {
                              final succ = await saveAction();
                              if (context.mounted && succ) {
                                Navigator.of(context).pop();
                                simpleSnack(context, "Saved!");
                              }
                            },
                            child: Text("Save & exit"),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The common UI elements for a edit screen
/// Supports: discard, delete, save, and dismiss error messages
class EditScaffoldForVm<R extends Identifiable> extends StatelessWidget {
  const EditScaffoldForVm({super.key, required this.title, required this.body, required this.vm});

  final EditVm<R, Draft<R>> vm;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !vm.isDirty,
      onPopInvokedWithResult: (didPop, Object? res) async {
        if (didPop || !vm.isDirty) return;

        if ((await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => ConfirmDialog(
                    title: "Discard changes?",
                    action: () {
                      Navigator.pop(dialogContext, true);
                    },
                    actionName: "discard",
                  ),
                ) ??
                false) &&
            context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("$title${vm.isDirty ? " *" : ""}"),
          actions: [
            IconButton(icon: const Icon(Icons.save), onPressed: vm.isDirty ? vm.save : null),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => ConfirmDialog(
                    title: "Are you sure?",
                    action: () async {
                      await vm.delete();

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (context.mounted && vm.errorMsg == null) {
                        Navigator.of(context).pop("deleted");
                        simpleSnack(context, "Deleted");
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (vm.errorMsg case String msg)
                MaterialBanner(
                  content: Text(msg),
                  actions: [TextButton(onPressed: vm.dismissError, child: const Text("Dismiss"))],
                ),
              Expanded(child: body),
              if (vm.isDirty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SafeArea(
                    child: TextButton(
                      onPressed: () async {
                        await vm.save();
                        if (context.mounted && vm.errorMsg == null) {
                          Navigator.of(context).pop();
                          simpleSnack(context, "Saved!");
                        }
                      },
                      child: Text("Save & exit"),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
