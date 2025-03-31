// ignore_for_file: avoid_print

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
        create: (_) => EventModel(appState),
        child: Builder(builder: (context) {
          final evm = Provider.of<EventModel>(context, listen: false);

          return Scaffold(
            appBar: AppBar(
              title: Text('Events'),
              actions: [
                // import button
                TextButton.icon(
                  onPressed: () async {
                    final fpRes = await FilePicker.platform.pickFiles();
                    if (fpRes == null) {
                      return; // canceled
                    }
                    final path = fpRes.files.single.path;
                    if (path == null) {
                      return;
                    }
                    final nEvt = await evm.importEvents(path);

                    if (context.mounted) {
                      final snackBar =
                          SnackBar(content: Text('imported $nEvt events'));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                  },
                  label: Text("import"),
                  icon: Icon(Icons.download),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final nEvt = await appState.db.exportEvents();

                    if (context.mounted) {
                      final snackBar =
                          SnackBar(content: Text('saved $nEvt events'));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                  },
                  label: Text("export"),
                  icon: Icon(Icons.upload),
                )
              ],
              bottom: TabBar(
                tabs: [
                  Tab(
                    text: "add",
                  ),
                  Tab(text: "history"),
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

// class EventExportDialog extends SimpleDialog {}
