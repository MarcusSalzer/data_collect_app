import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/screens/events/complete_export_screen.dart';
import 'package:data_app2/view_models/evt_create_vm.dart';
import 'package:data_app2/widgets/evt_create_menu.dart';
import 'package:data_app2/widgets/evt_history_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.select<AppState, AppPrefs>((a) => a.prefs);

    return DefaultTabController(
      length: 2,
      child: ChangeNotifierProvider<EvtCreateVm>(
        create: (createCtx) {
          final app = createCtx.read<AppState>();
          return EvtCreateVm(app.db, app.evtTypeManager, prefs.autoLowerCase)..load();
        },
        child: Builder(
          builder: (context) {
            final evtVm = context.watch<EvtCreateVm>();
            return Scaffold(
              appBar: AppBar(
                title: const Text('Events'),
                actions: [
                  IconButton(
                    onPressed: context.read<EvtCreateVm>().refreshSuggestions,
                    icon: Icon(Icons.refresh),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CompleteExportScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Export"),
                    ),
                  ),
                ],
                bottom: TabBar(
                  tabs: [
                    const Tab(text: "add"),
                    const Tab(text: "history"),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  EvtCreateMenu(),
                  EvtHistoryList(
                    evtVm.evts,
                    evtVm.load,
                    reversed: true,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
