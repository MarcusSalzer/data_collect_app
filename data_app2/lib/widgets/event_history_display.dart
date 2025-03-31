// ignore_for_file: avoid_print

import 'package:data_app2/db_service.dart';
import 'package:data_app2/event_model.dart';
import 'package:data_app2/screens/event_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventHistoryDisplay extends StatelessWidget {
  const EventHistoryDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Consumer<EventModel>(
        builder: (context, evtModel, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(evtModel.evtCount != null
                  ? "has ${evtModel.evtCount} events"
                  : "loading..."),
              Expanded(
                child: ListView.builder(
                    itemCount: evtModel.events.length,
                    itemBuilder: (context, i) {
                      final evt = evtModel.events[i];
                      final start = evt.start;
                      final end = evt.end;
                      final startText = start != null
                          ? DateFormat("HH:mm").format(start)
                          : "__:__";
                      final endText = end != null
                          ? DateFormat("HH:mm").format(end)
                          : "__:__";

                      return EventListTile(
                          evt: evt,
                          subt: "$startText - $endText",
                          evtModel: evtModel);
                    }),
              )
            ],
          );
        },
      ),
    );
  }
}

class EventListTile extends StatelessWidget {
  const EventListTile({
    super.key,
    required this.evt,
    required this.subt,
    required this.evtModel,
  });

  final Event evt;
  final String subt;
  final EventModel evtModel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(evt.name),
      subtitle: subt.isNotEmpty ? Text(subt) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ChangeNotifierProvider<EventModel>.value(
                          value: evtModel, child: EventEditScreen(evt)),
                ),
              );
            },
            icon: Icon(Icons.edit),
          ),
          SizedBox(width: 10),
          MenuAnchor(
            builder: (context, controller, child) => IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: Icon(Icons.delete_forever),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: () {
                  evtModel.delete(evt);
                },
                child: Text('Delete'),
              )
            ],
          ),
        ],
      ),
    );
  }
}
