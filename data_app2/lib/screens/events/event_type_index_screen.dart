import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/screens/events/multi_evt_type_summary_screen.dart';
import 'package:data_app2/view_models/evt_type_index_vm.dart';
import 'package:data_app2/screens/events/event_type_detail_screen.dart';
import 'package:data_app2/screens/events/evt_type_overview_screen.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:data_app2/widgets/dangling_type_refs_warning_box.dart';
import 'package:data_app2/widgets/selection_fab.dart';
import 'package:data_app2/widgets/selection_list.dart';
import 'package:data_app2/widgets/selection_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _Body extends StatelessWidget {
  final Color Function(EvtTypeRec) colorOf;
  const _Body(this.colorOf);
  @override
  Widget build(BuildContext context) {
    return Consumer<EvtTypeIndexVm>(
      builder: (context, indexVM, child) {
        return Builder(
          builder: (context) {
            final items = indexVM.itemsSorted;
            if (items == null) {
              return Center(child: Text("Loading..."));
            }
            if (items.isEmpty) {
              return Center(child: Text("No categories"));
            }

            final danglingTypeRefs = indexVM.danglingTypeRefs;
            if (danglingTypeRefs.isNotEmpty) {
              return Column(
                children: [
                  DanglingTypeRefsWarningBox(danglingTypeRefs),
                  TextButton(
                    onPressed: () async {
                      final created = await indexVM.recreateDanglingTypes();
                      if (context.mounted) {
                        simpleSnack(context, "created: ${created.join(', ')}");
                      }
                    },
                    child: Text("recreate missing types"),
                  ),
                ],
              );
            }
            return SelectionList<EvtTypeRec>(
              colorOf: colorOf,
              subtitleOf: (r) => indexVM.countOf(r).toString(),
              onTapItem: (r) {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EvtTypeOverviewScreen(r))).then((_) {
                  // reload data
                  indexVM.load();
                });
              },
            );
          },
        );
      },
    );
  }
}

/// Screen showing a list of all event types, and more.
@Deprecated("types and cats on same screen")
class EventTypeIndexScreen extends StatelessWidget {
  const EventTypeIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctxCreate) {
            final app = ctxCreate.read<AppState>();
            final vm = EvtTypeIndexVm(app.db, app.evtTypeManager);
            vm.load();
            return vm;
          },
        ),
        ChangeNotifierProvider(
          create: (ctxCreate) {
            final indexVm = ctxCreate.read<EvtTypeIndexVm>();
            final searchMode = ctxCreate.read<AppState>().prefs.textSearchMode;

            return GenericSelectionVm<EvtTypeRec>(
              source: () => indexVm.itemsSorted ?? [],
              idOf: (r) => r.id,
              textOf: (r) => r.name,
              searchMode: searchMode,
            );
          },
        ),
      ],
      child: Scaffold(
        appBar: SelectionAppBar<EvtTypeRec>("Event types"),
        body: _Body(context.read<AppState>().colorFor),
        floatingActionButton: SelectionFab<EvtTypeRec>(
          // has selection: show summary for selection
          actionSelectedName: "Summary",
          actionSelected: (selected) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => MultiEvtTypeSummaryScreen(typeIds: selected)));
          },
          actionEmpty: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventTypeDetailScreen(null))).then((_) {
              if (context.mounted) {
                // Reload data after possible edits
                context.read<EvtTypeIndexVm>().load();
              }
            });
          },
        ),
      ),
    );
  }
}
