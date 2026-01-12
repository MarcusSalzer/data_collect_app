import 'package:data_app2/app_state.dart';
import 'package:data_app2/screens/events/multi_evt_type_summary_screen.dart';
import 'package:data_app2/view_models/event_type_index_view_model.dart';
import 'package:data_app2/view_models/event_type_selection_vm.dart';
import 'package:data_app2/screens/events/event_type_detail_screen.dart';
import 'package:data_app2/screens/events/event_type_overview_screen.dart';
import 'package:data_app2/util.dart';
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
            final evtFreqs = indexVM.evtFreqs?.entries.toList();

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

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Event types'),
      actions: [
        Consumer<EventTypeSelectionVM>(
          builder: (context, selVM, _) {
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: selVM.selectAll,
                ),
                if (selVM.anySelected)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: selVM.clearSelection,
                  ),
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

class _Scaffold extends StatelessWidget {
  const _Scaffold();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _AppBar(),
      body: _Body(),
      floatingActionButton: Consumer<EventTypeSelectionVM>(
        builder: (context, selVM, child) {
          if (selVM.anySelected) {
            return FloatingActionButton.extended(
              icon: const Icon(Icons.analytics),
              label: Text('Summary (${selVM.selected.length})'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        MultiEvtTypeSummaryScreen(typeIds: selVM.selected),
                  ),
                );
              },
            );
          }

          // default FAB
          return FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => EventTypeDetailScreen(null),
                    ),
                  )
                  .then((_) {
                    if (context.mounted) {
                      context.read<EventTypeIndexViewModel>().load();
                    }
                  });
            },
          );
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
    return ChangeNotifierProvider<EventTypeIndexViewModel>(
      create: (_) {
        final app = Provider.of<AppState>(context, listen: false);
        return EventTypeIndexViewModel(app)..load();
      },
      child: Builder(
        builder: (context) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(
                value: context.read<EventTypeIndexViewModel>(),
              ),
              ChangeNotifierProvider(
                create: (context) => EventTypeSelectionVM(
                  context.read<EventTypeIndexViewModel>(),
                  Provider.of<AppState>(context, listen: false),
                ),
              ),
            ],
            child: _Scaffold(),
          );
        },
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
          Text(
            "We have dangling type references",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            danglingTypeRefs.toString(),
            style: TextStyle(fontFamily: "monospace"),
          ),
          Text("Try importing the correct types, or make new ones to override"),
        ],
      ),
    );
  }
}

class EvtTypeSearch extends StatelessWidget {
  const EvtTypeSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EventTypeSelectionVM>();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Filter',
          border: OutlineInputBorder(),
        ),
        onChanged: vm.setQuery,
      ),
    );
  }
}

/// List showing event types.
class EvtTypeList extends StatelessWidget {
  const EvtTypeList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<EventTypeSelectionVM, EventTypeIndexViewModel>(
      builder: (context, selVM, dataVM, _) {
        final evtTypes = selVM.filtered;
        return Column(
          children: [
            EvtTypeSearch(),
            Expanded(
              child: ListView.builder(
                itemCount: evtTypes.length,
                itemBuilder: (context, index) {
                  final typeRec = evtTypes[index];
                  final id = typeRec.id!;
                  final count = dataVM.evtFreqs?[id] ?? 0;

                  return ListTile(
                    leading: Checkbox(
                      value: selVM.isSelected(id),
                      onChanged: (_) {
                        selVM.toggle(id);
                      },
                    ),
                    title: Text(
                      typeRec.name,
                      style: TextStyle(color: typeRec.color.inContext(context)),
                    ),
                    subtitle: Text(count.toString()),
                    trailing: IconButton(
                      onPressed: () {
                        final typeId = typeRec.id;
                        if (typeId != null) {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EventTypeOverviewScreen(typeId),
                                ),
                              )
                              .then((_) {
                                // reload data
                                dataVM.load();
                              });
                        } else {
                          simpleSnack(
                            context,
                            "error: cannot find type $typeId",
                          );
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
