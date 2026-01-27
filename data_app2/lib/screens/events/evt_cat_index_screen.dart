import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_cat_rec.dart';
import 'package:data_app2/view_models/event_cat_index_view_model.dart';
import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EvtCatIndexScreen extends StatelessWidget {
  const EvtCatIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context, listen: false);

    // Create both view models.

    final indexVm = EventCatIndexViewModel(app);
    final eventTypeSelection = GenericSelectionVm<EvtCatRec>(
      source: () => indexVm.itemsSorted,
      idOf: (r) => r.id,
      textOf: (r) => r.name,
      app: app,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => indexVm..load()),
        ChangeNotifierProvider(create: (context) => eventTypeSelection),
      ],
      child: Placeholder(),
    );
  }
}
