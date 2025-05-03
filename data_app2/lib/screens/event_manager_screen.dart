// favorites
//   - colors?
// categories

import 'package:data_app2/app_state.dart';
import 'package:data_app2/event_model.dart';
import 'package:data_app2/screens/event_type_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventManagerScreen extends StatelessWidget {
  const EventManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return ChangeNotifierProvider<EventModel>(
      create: (_) => EventModel(appState, nList: 100),
      child: Builder(builder: (context) {
        return Scaffold(
            appBar: AppBar(
              title: const Text('Event types'),
            ),
            body: Consumer<EventModel>(
              builder: (context, value, child) {
                final evtFreqs = value.evtFreqs.entries.toList();

                return ListView.builder(
                  itemCount: evtFreqs.length,
                  itemBuilder: (context, index) {
                    final MapEntry(key: name, value: count) = evtFreqs[index];
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(
                        count.toString(),
                      ),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              EventTypeScreen(appState, name: name),
                        ));
                      },
                    );
                  },
                );
              },
            ));
      }),
    );
  }
}
