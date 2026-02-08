import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_cat.dart';
import 'package:data_app2/screens/events/evt_cat_detail_screen.dart';
import 'package:data_app2/view_models/evt_cat_index_vm.dart';
import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:data_app2/widgets/selection_app_bar.dart';
import 'package:data_app2/widgets/selection_fab.dart';
import 'package:data_app2/widgets/selection_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _Body extends StatelessWidget {
  const _Body();
  @override
  Widget build(BuildContext context) {
    return Consumer<EvtCatIndexVm>(
      builder: (context, indexVM, child) {
        final idToCount = indexVM.idToCount;
        final items = indexVM.itemsSorted;

        if (items == null) {
          return Center(child: Text("Loading..."));
        }
        if (items.isEmpty) {
          return Center(child: Text("No categories"));
        }

        return SelectionList<EvtCatRec>(
          colorOf: (c) => const Color.fromARGB(237, 200, 124, 124),
          countOf: (c) => idToCount?[c.id] ?? 0,
          onTapItem: (rec) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => EvtCatDetailScreen(rec))).then((_) {
              // reload data
              print("reload");
              indexVM.load();
            });
          },
        );
      },
    );
  }
}

class EvtCatIndexScreen extends StatelessWidget {
  const EvtCatIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context, listen: false);

    // Create both view models.

    final indexVm = EvtCatIndexVm(app);
    final selectionVm = GenericSelectionVm<EvtCatRec>(
      source: () => indexVm.itemsSorted ?? [],
      idOf: (r) => r.id,
      textOf: (r) => r.name,
      app: app,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => indexVm..load()),
        ChangeNotifierProvider(create: (context) => selectionVm),
      ],
      child: Scaffold(
        appBar: SelectionAppBar<EvtCatRec>("Event Categories"),
        body: _Body(),
        floatingActionButton: SelectionFab<EvtCatRec>(
          // has selection: show summary for selection
          actionSelectedName: "Nothing",
          actionSelected: (ids) {},
          actionEmpty: () {
            // Create new
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => EvtCatDetailScreen(null))).then((_) {
              // Reload data after possible edits
              print("reload (new)");
              indexVm.load();
            });
          },
        ),
      ),
    );
  }
}
