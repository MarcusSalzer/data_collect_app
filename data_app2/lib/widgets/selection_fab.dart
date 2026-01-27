import 'package:data_app2/data/evt_type_rec.dart';
import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dynamic Floating action button with actions for (non)empty selections
/// Needs an [GenericSelectionVm] in context
class SelectionFab extends StatelessWidget {
  final String actionSelectedName;
  final void Function(Set<int>) actionSelected;
  final void Function() actionEmpty;

  const SelectionFab({
    required this.actionSelectedName,
    required this.actionSelected,
    required this.actionEmpty,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GenericSelectionVm<EvtTypeRec>>(
      builder: (context, selVM, child) {
        // special selection FAB
        if (selVM.anySelected) {
          return FloatingActionButton.extended(
            icon: const Icon(Icons.analytics),
            label: Text('$actionSelectedName (${selVM.selected.length})'),
            onPressed: () {
              actionSelected(selVM.selected);
            },
          );
        }
        // default FAB
        return FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            actionEmpty();
          },
        );
      },
    );
  }
}
