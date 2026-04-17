import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/evt_type.dart';
import 'package:data_app2/screens/events/evt_cat_detail_screen.dart';
import 'package:data_app2/screens/events/multi_evt_type_summary_screen.dart';
import 'package:data_app2/view_models/evt_cat_index_vm.dart';
import 'package:data_app2/view_models/evt_type_index_vm.dart';
import 'package:data_app2/screens/events/event_type_detail_screen.dart';
import 'package:data_app2/screens/events/evt_type_overview_screen.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:data_app2/widgets/dangling_type_refs_warning_box.dart';
import 'package:data_app2/widgets/reusable_icons.dart';
import 'package:data_app2/widgets/selection_fab.dart';
import 'package:data_app2/widgets/selection_list.dart';
import 'package:data_app2/widgets/selection_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _BodyEvtTypes extends StatelessWidget {
  const _BodyEvtTypes();
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
                ],
              );
            }
            return SelectionList<EvtTypeRec>(
              colorOf: context.read<AppState>().colorFor,
              countOf: indexVM.countOf,
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

class _BodyEvtCats extends StatelessWidget {
  const _BodyEvtCats();
  @override
  Widget build(BuildContext context) {
    return Consumer<EvtCatIndexVm>(
      builder: (context, indexVM, child) {
        final idToCount = indexVM.idToCount;
        final items = indexVM.itemsSorted;

        if (items == null || idToCount == null) {
          return Center(child: Text("Loading..."));
        }
        if (items.isEmpty) {
          return Center(child: Text("No categories"));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final rec = items[index];

            return ListTile(
              title: Text(rec.name, style: TextStyle(color: rec.color)),
              subtitle: Text("${idToCount[rec.id] ?? 0} types"),
              trailing: indexVM.isDefault(rec.id) ? Text("(default)") : null,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EvtCatDetailScreen(rec))).then((_) {
                  // reload BOTH VMs, since types can be updated
                  indexVM.load();
                  if (context.mounted) {
                    context.read<EvtTypeIndexVm>().load();
                  }
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
class EventTypeCatIndexScreen extends StatefulWidget {
  const EventTypeCatIndexScreen({super.key});

  @override
  State<EventTypeCatIndexScreen> createState() => _EventTypeCatIndexScreenState();
}

class _EventTypeCatIndexScreenState extends State<EventTypeCatIndexScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctxCreate) {
            final app = ctxCreate.read<AppState>();
            return EvtTypeIndexVm(app.db, app.evtTypeManager)..load();
          },
        ),
        ChangeNotifierProvider(
          create: (ctxCreate) {
            return EvtCatIndexVm(ctxCreate.read<AppState>().db)..load();
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
      child: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          final onCatsTab = _tabController.index == 1;
          return Scaffold(
            appBar: AppBar(
              title: Text(onCatsTab ? "My categories" : "My Events"),
              actions: onCatsTab ? null : [SelectionActions<EvtTypeRec>()],
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(icon: evtTypeIcon),
                  Tab(icon: evtCatIcon),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [_BodyEvtTypes(), _BodyEvtCats()],
            ),
            floatingActionButton: onCatsTab
                ? null
                : SelectionFab<EvtTypeRec>(
                    // has selection: show summary for selection
                    actionSelectedName: "Summary",
                    actionSelected: (selected) {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => MultiEvtTypeSummaryScreen(typeIds: selected)));
                    },
                    actionEmpty: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventTypeDetailScreen(null))).then((
                        _,
                      ) {
                        if (context.mounted) {
                          // Reload data after possible edits
                          context.read<EvtTypeIndexVm>().load();
                        }
                      });
                    },
                  ),
          );
        },
      ),
    );
  }
}
