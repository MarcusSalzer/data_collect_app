import 'package:data_app2/app_state.dart';
import 'package:data_app2/enums.dart';
import 'package:data_app2/event_model.dart';
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
      child: ChangeNotifierProvider<EventModel>(
        create: (_) => EventModel(appState, nList: 100),
        child: Builder(builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Events'),
              actions: [
                TextButton(
                  onPressed: () async {
                    // final nEvt = await evm.exportEvents();
                    // if (context.mounted) {
                    //   simpleSnack(context, "saved $nEvt events");
                    // }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ExportScreen(),
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
                EventCreateMenu(),
                Consumer<EventModel>(builder: (context, evtModel, child) {
                  return EventHistoryDisplay(
                    evtModel.events,
                    isScrollable: true,
                    headingMode: GroupFreq.day,
                    reloadAction: evtModel.load,
                  );
                }),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class EventsScreenExtraMenu extends StatelessWidget {
  const EventsScreenExtraMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) => IconButton(
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        icon: Icon(Icons.more_vert),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            // final nEvt = await evm.exportEvents();
            // if (context.mounted) {
            //   simpleSnack(context, "saved $nEvt events");
            // }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ExportScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Export"),
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: MenuItemButton(
        //     onPressed: () {
        //       showDialog(
        //           context: context,
        //           builder: (context) {
        //             return NormalizeDialog(evm);
        //           });
        //     },
        //     child: Text('normalize'),
        //   ),
        // )
      ],
    );
  }
}

class NormalizeDialog extends StatelessWidget {
  final EventModel evm;

  const NormalizeDialog(
    this.evm, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.all(20),
      title: Text("Dataset normalization"),
      children: [
        Center(
            child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text("Note: these actions are permanent"),
        )),
        // Padding(
        //   padding: const EdgeInsets.symmetric(vertical: 10),
        //   child: TextButton(
        //     onPressed: () async {
        //       final c = await evm.normalizeLowerAll();

        //       if (context.mounted) {
        //         Navigator.pop(context);
        //         ScaffoldMessenger.of(context).showSnackBar(
        //           SnackBar(
        //             content: Text("normalized (lowercase) $c events"),
        //           ),
        //         );
        //       }
        //     },
        //     child: Text("Lowercase"),
        //   ),
        // ),
        // Padding(
        //   padding: const EdgeInsets.symmetric(vertical: 10),
        //   child: TextButton(
        //     onPressed: () async {
        //       final c = await evm.normalizeStripAll();

        //       if (context.mounted) {
        //         Navigator.pop(context);
        //         ScaffoldMessenger.of(context).showSnackBar(
        //           SnackBar(
        //             content: Text("normalized (strip) $c events"),
        //           ),
        //         );
        //       }
        //     },
        //     child: Text("Strip whitespace"),
        //   ),
        // ),
      ],
    );
  }
}
