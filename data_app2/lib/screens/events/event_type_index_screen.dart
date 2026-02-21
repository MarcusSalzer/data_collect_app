import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/screens/events/multi_evt_type_summary_screen.dart';
import 'package:data_app2/util/colors.dart';
import 'package:data_app2/view_models/evt_type_index_vm.dart';
import 'package:data_app2/screens/events/event_type_detail_screen.dart';
import 'package:data_app2/screens/events/event_type_overview_screen.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:data_app2/widgets/selection_fab.dart';
import 'package:data_app2/widgets/selection_list.dart';
import 'package:data_app2/widgets/selection_search_box.dart';
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
              countOf: indexVM.countOf,
              onTapItem: (r) {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventTypeOverviewScreen(r.id))).then(
                  (_) {
                    // reload data
                    indexVM.load();
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Screen showing a list of all event types, and more.
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

class DanglingTypeRefsWarningBox extends StatelessWidget {
  final Iterable<int> danglingTypeRefs;

  const DanglingTypeRefsWarningBox(this.danglingTypeRefs, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.brown,
      padding: EdgeInsets.all(8),
      child: Column(
        spacing: 12,
        children: [
          Text("We have dangling type references", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(danglingTypeRefs.toString(), style: TextStyle(fontFamily: "monospace")),
          Text("Try importing the correct types, or make new ones to override"),
        ],
      ),
    );
  }
}

/// List showing event types.
@Deprecated("MAYBE use SelectionList instead")
class EvtTypeList extends StatelessWidget {
  const EvtTypeList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GenericSelectionVm<EvtTypeRec>, EvtTypeIndexVm>(
      builder: (context, selVM, dataVM, _) {
        final evtTypes = selVM.filtered;
        return Column(
          children: [
            SelectionSearchBox<EvtTypeRec>(),
            Expanded(
              child: ListView.builder(
                itemCount: evtTypes.length,
                itemBuilder: (context, index) {
                  final typeRec = evtTypes[index];
                  final count = dataVM.idToCount?[typeRec.id] ?? 0;

                  return ListTile(
                    leading: Checkbox(
                      value: selVM.isSelected(typeRec.id),
                      onChanged: (_) {
                        selVM.toggle(typeRec.id);
                      },
                    ),

                    title: Text(typeRec.name, style: TextStyle(color: ColorEngine.defaultColor)),
                    subtitle: Text(count.toString()),
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (context) => EventTypeOverviewScreen(typeRec.id))).then((_) {
                        // reload data
                        dataVM.load();
                      });
                    },
                    trailing: IconButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (context) => EventTypeDetailScreen(typeRec))).then((_) {
                          // reload data
                          dataVM.load();
                        });
                      },
                      icon: Icon(Icons.edit),
                    ),
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
