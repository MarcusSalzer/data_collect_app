// favorites
//   - colors?
// categories

import 'package:data_app2/app_state.dart';
import 'package:data_app2/event_model.dart';
import 'package:data_app2/screens/events/event_type_screen.dart';
import 'package:data_app2/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventManagerScreen extends StatelessWidget {
  const EventManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    return ChangeNotifierProvider<EventModel>(
      create: (_) => EventModel(app, nList: 100),
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
                    final MapEntry(key: typeId, value: count) = evtFreqs[index];
                    return ListTile(
                      title: Text(app.eventName(typeId) ?? "unknown"),
                      subtitle: Text(
                        count.toString(),
                      ),
                      onTap: () async {
                        final type = await app.db.getEventType(id: typeId);
                        if (context.mounted) {
                          if (type != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EventTypeScreen(
                                  app,
                                  type: type,
                                ),
                              ),
                            );
                          } else {
                            simpleSnack(
                                context, "error: cannot find type $typeId");
                          }
                        }
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
