import 'package:data_app2/app_state.dart';
import 'package:data_app2/custom_render_plot/location_scatter.dart';
import 'package:data_app2/data/location.dart';
import 'package:data_app2/location_manager.dart';
import 'package:data_app2/screens/location_detail_screen.dart';
import 'package:data_app2/view_models/generic_selection_vm.dart';
import 'package:data_app2/view_models/location_index_vm.dart';
import 'package:data_app2/widgets/selection_app_bar.dart';
import 'package:data_app2/widgets/selection_fab.dart';
import 'package:data_app2/widgets/selection_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _BodyLocationList extends StatelessWidget {
  const _BodyLocationList();
  @override
  Widget build(BuildContext context) {
    return Consumer<LocationIndexVm>(
      builder: (context, indexVM, child) {
        return Builder(
          builder: (context) {
            final items = indexVM.itemsSorted;
            if (items == null) {
              return Center(child: Text("Loading..."));
            }
            if (items.isEmpty) {
              return Center(child: Text("No locations"));
            }

            return SelectionList<LocationRec>(
              subtitleOf: (r) => "${r.lat}, ${r.lng}",
              onTapItem: (r) {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => LocationEditScreen(
                          existing: r,
                          repo: context.read<AppState>().db.locations,
                          manager: context.read<LocationManager>(),
                        ),
                      ),
                    )
                    .then((_) {
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

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> with SingleTickerProviderStateMixin {
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
            return LocationIndexVm(app.db, ctxCreate.read<LocationManager>())..load();
          },
        ),

        ChangeNotifierProvider(
          create: (ctxCreate) {
            final indexVm = ctxCreate.read<LocationIndexVm>();
            final searchMode = ctxCreate.read<AppState>().prefs.textSearchMode;

            return GenericSelectionVm<LocationRec>(
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
          final onIndexTab = _tabController.index == 0;

          return Scaffold(
            appBar: AppBar(
              title: Text("Locations"),
              actions: onIndexTab ? [SelectionActions<LocationRec>()] : null,
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(icon: Icon(Icons.list)),
                  Tab(icon: Icon(Icons.timeline)),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [_BodyLocationList(), LocationScatterMap()],
            ),
            floatingActionButton: onIndexTab
                ? SelectionFab<LocationRec>(
                    // has selection: show summary for selection
                    actionSelectedName: "Summary",
                    actionSelected: (selected) {
                      // Navigator.of(
                      //   context,
                      // ).push(MaterialPageRoute(builder: (_) => MultiEvtTypeSummaryScreen(typeIds: selected)));
                    },
                    actionEmpty: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => LocationEditScreen(
                                existing: null,
                                repo: context.read<AppState>().db.locations,
                                manager: context.read<LocationManager>(),
                              ),
                            ),
                          )
                          .then((
                            _,
                          ) {
                            if (context.mounted) {
                              // Reload data after possible edits
                              context.read<LocationIndexVm>().load();
                            }
                          });
                    },
                  )
                : null,
          );
        },
      ),
    );
  }
}
