import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Appbar with selection-actions. Needs a [GenericSelectionVm] in context
class SelectionAppBar<T> extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SelectionAppBar(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        Consumer<GenericSelectionVm<T>>(
          builder: (context, selVM, _) {
            return Row(
              children: [
                IconButton(icon: const Icon(Icons.select_all), onPressed: selVM.selectAll),
                if (selVM.anySelected) IconButton(icon: const Icon(Icons.clear), onPressed: selVM.clearSelection),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
