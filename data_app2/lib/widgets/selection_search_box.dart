import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// UI for search/filter-selection. Needs a [GenericSelectionVm] provider in context
class SelectionSearchBox<T> extends StatelessWidget {
  const SelectionSearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Filter',
          border: OutlineInputBorder(),
        ),
        // dont call in build, but ok in event handler (See docs for context.read)
        onChanged: context.read<GenericSelectionVm<T>>().setQuery,
      ),
    );
  }
}
