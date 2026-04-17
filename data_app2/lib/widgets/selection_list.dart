import 'package:data_app2/contracts/data.dart';
import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:data_app2/widgets/selection_search_box.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Color defaultColor(_) => Colors.red;

/// List showing event types.
class SelectionList<T extends Identifiable> extends StatelessWidget {
  final Color Function(T)? colorOf;
  final int Function(T)? countOf;
  final void Function(T)? onTapItem;
  const SelectionList({super.key, this.colorOf = defaultColor, this.countOf, required this.onTapItem});

  @override
  Widget build(BuildContext context) {
    return Consumer<GenericSelectionVm<T>>(
      builder: (context, selVM, _) {
        final items = selVM.filtered;
        final cbTap = onTapItem;
        final cbColor = colorOf;
        final cbSubtitle = countOf;

        return Column(
          children: [
            SelectionSearchBox<T>(),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final rec = items[index];
                  final id = rec.id;

                  return ListTile(
                    leading: Checkbox(
                      value: selVM.isSelected(rec.id),
                      onChanged: (_) {
                        selVM.toggle(id);
                      },
                    ),
                    title: Text(selVM.textOf(rec), style: (cbColor != null) ? TextStyle(color: cbColor(rec)) : null),
                    subtitle: (cbSubtitle != null) ? Text(cbSubtitle(rec).toString()) : null,
                    onTap: (cbTap != null) ? () => cbTap(rec) : null,
                    // trailing: IconButton(
                    //   onPressed: () {
                    //
                    //   },
                    //   icon: Icon(Icons.stacked_bar_chart),
                    // ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
