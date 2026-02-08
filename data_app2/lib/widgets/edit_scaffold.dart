import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/contracts/edit_vm.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';

/// The common UI elements for a edit screen
class EditScaffold<R extends Identifiable> extends StatelessWidget {
  const EditScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.confirmDiscard,
    required this.vm,
  });

  final EditVm<R, Draft<R>> vm;
  final String title;
  final Widget body;

  /// Return true = allow pop
  final Future<bool> Function() confirmDiscard;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !vm.isDirty,
      onPopInvokedWithResult: (didPop, Object? res) async {
        if (didPop || !vm.isDirty) return;

        if (await confirmDiscard() && context.mounted) {
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
                showDialog(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    title: "Are you sure?",
                    action: () async {
                      final didDelete = await vm.delete();
                      if (context.mounted) {
                        if (didDelete) {
                          simpleSnack(context, "Deleted");
                        } else {
                          simpleSnack(context, "Failed to delete", color: Colors.red);
                        }
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (vm.errorMsg case String msg)
              MaterialBanner(
                content: Text(msg),
                actions: [TextButton(onPressed: () {}, child: const Text("Dismiss"))],
              ),
            Expanded(child: body),
            if (vm.isDirty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SafeArea(
                  child: TextButton(
                    onPressed: () async {
                      await vm.save();
                      if (context.mounted) {
                        simpleSnack(context, "Saved!");
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text("Save & exit"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
