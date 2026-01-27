import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_type_rec.dart';
import 'package:data_app2/screens/events/multi_evt_type_summary_screen.dart';
import 'package:data_app2/view_models/event_type_index_view_model.dart';
import 'package:data_app2/screens/events/event_type_detail_screen.dart';
import 'package:data_app2/screens/events/event_type_overview_screen.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:data_app2/widgets/selection_fab.dart';
import 'package:data_app2/widgets/selection_search_box.dart';
import 'package:data_app2/widgets/selection_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _Body extends StatelessWidget {
  const _Body();
  @override
  Widget build(BuildContext context) {
    return Consumer<EventTypeIndexViewModel>(
      builder: (context, indexVM, child) {
        return Builder(
          builder: (context) {
            final evtFreqs = indexVM.idToCount;

            if (evtFreqs == null) {
              return Center(child: Text("Loading..."));
            }
            if (evtFreqs.isEmpty) {
              return Center(child: Text("No event types"));
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
                  Expanded(child: EvtTypeList()),
                ],
              );
            }
            return EvtTypeList();
          },
        );
      },
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SelectionAppBar<EvtTypeRec>("Event types"),
      body: _Body(),
      floatingActionButton: SelectionFab(
        // has selection: show summary for selection
        actionSelectedName: "Summary",
        actionSelected: (selected) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => MultiEvtTypeSummaryScreen(typeIds: selected)));
        },
        actionEmpty: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventTypeDetailScreen(null))).then((_) {
            if (context.mounted) {
              // Reload data after possible edits
              context.read<EventTypeIndexViewModel>().load();
            }
          });
        },
      ),
    );
  }
}

/// Screen showing a list of all event types, and more.
class EventTypeIndexScreen extends StatelessWidget {
  const EventTypeIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context, listen: false);

    // Create both view models.

    final indexVm = EventTypeIndexViewModel(app);
    final selectionVm = GenericSelectionVm<EvtTypeRec>(
      source: () => indexVm.itemsSorted,
      idOf: (r) => r.id,
      textOf: (r) => r.name,
      app: app,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => indexVm..load()),
        ChangeNotifierProvider(create: (context) => selectionVm),
      ],
      child: _Scaffold(),
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
class EvtTypeList extends StatelessWidget {
  const EvtTypeList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GenericSelectionVm<EvtTypeRec>, EventTypeIndexViewModel>(
      builder: (context, selVM, dataVM, _) {
        final evtTypes = selVM.filtered;
        return Column(
          children: [
            SelectionSearchBox(),
            Expanded(
              child: ListView.builder(
                itemCount: evtTypes.length,
                itemBuilder: (context, index) {
                  final typeRec = evtTypes[index];
                  final id = typeRec.id!;
                  final count = dataVM.idToCount?[id] ?? 0;

                  return ListTile(
                    leading: Checkbox(
                      value: selVM.isSelected(id),
                      onChanged: (_) {
                        selVM.toggle(id);
                      },
                    ),
                    title: Text(typeRec.name, style: TextStyle(color: typeRec.color.inContext(context))),
                    subtitle: Text(count.toString()),
                    trailing: IconButton(
                      onPressed: () {
                        final typeId = typeRec.id;
                        if (typeId != null) {
                          Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (context) => EventTypeOverviewScreen(typeId))).then((_) {
                            // reload data
                            dataVM.load();
                          });
                        } else {
                          simpleSnack(context, "error: cannot find type $typeId");
                        }
                      },
                      icon: Icon(Icons.stacked_bar_chart),
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
