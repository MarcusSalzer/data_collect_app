import 'package:data_app2/app_state.dart';
import 'package:data_app2/event_model.dart';
import 'package:data_app2/widgets/event_create_menu.dart';
import 'package:data_app2/widgets/event_history_display.dart';
import 'package:file_picker/file_picker.dart';
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
                EventsScreenExtraMenu(),
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
                EventHistoryDisplay(),
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
    final evm = Provider.of<EventModel>(context, listen: false);
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: MenuItemButton(
            onPressed: () async {
              final fpRes = await FilePicker.platform.pickFiles();
              if (fpRes == null) {
                return; // canceled
              }
              final path = fpRes.files.single.path;
              if (path == null) {
                return;
              }
              try {
                final nEvt = await evm.importEvents(path);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('imported $nEvt events'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'error: $e',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text("import"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: MenuItemButton(
            onPressed: () async {
              final nEvt = await evm.exportEvents();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('saved $nEvt events'),
                  ),
                );
              }
            },
            child: Text("export"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: MenuItemButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return NormalizeDialog(evm);
                  });
            },
            child: Text('normalize'),
          ),
        )
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: TextButton(
            onPressed: () async {
              final c = await evm.normalizeLowerAll();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("normalized (lowercase) $c events"),
                  ),
                );
              }
            },
            child: Text("Lowercase"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: TextButton(
            onPressed: () async {
              final c = await evm.normalizeStripAll();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("normalized (strip) $c events"),
                  ),
                );
              }
            },
            child: Text("Strip whitespace"),
          ),
        ),
      ],
    );
  }
}
