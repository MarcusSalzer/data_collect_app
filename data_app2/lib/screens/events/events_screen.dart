import 'package:data_app2/app_state.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/view_models/event_create_vm.dart';
import 'package:data_app2/screens/events/events_export_screen.dart';
import 'package:data_app2/widgets/event_create_menu.dart';
import 'package:data_app2/widgets/event_history_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: ChangeNotifierProvider<EventCreateViewVM>(
        create: (_) => EventCreateViewVM(appState),
        child: Builder(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Events'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => ExportScreen()));
                    },
                    child: Padding(padding: const EdgeInsets.all(8.0), child: Text("Export")),
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
                  EventCreateMenu(),
                  Consumer<EventCreateViewVM>(
                    builder: (context, evtModel, child) {
                      return EventHistoryDisplay(
                        evtModel.events.reversed.toList(),
                        isScrollable: true,
                        headingMode: GroupFreq.day,
                        reloadAction: evtModel.load,
                      );
                    },
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
