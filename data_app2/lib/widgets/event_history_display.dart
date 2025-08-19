// ignore_for_file: avoid_print

import 'package:data_app2/app_state.dart' show AppState;
import 'package:data_app2/db_service.dart';
import 'package:data_app2/event_model.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/screens/events/event_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventHistoryDisplay extends StatelessWidget {
  const EventHistoryDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Consumer<EventModel>(
        builder: (context, evtModel, child) {
          final count = evtModel.events.length;
          return ListView.builder(
            itemCount: count,
            itemBuilder: (context, i) {
              return EventListTile(
                // reverse order
                evt: evtModel.events[i],
                evtModel: evtModel,
              );
            },
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
    required this.evtModel,
  });

  final Event evt;
  final EventModel evtModel;

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context, listen: false);
    final (startText, endText) = Fmt.eventTimes(evt);

    final start = evt.start;
    final end = evt.end;
    String durTxt;
    if (start != null && end != null) {
      final dur = end.difference(start);
      durTxt = " (${Fmt.durationHM(dur)})";
    } else {
      durTxt = "";
    }

    return ListTile(
      title: Text(app.eventName(evt.typeId)! + durTxt),
      subtitle: Text(
        "$startText - $endText",
        style: TextStyle(fontFamily: 'monospace'),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider<EventModel>.value(
              value: evtModel,
              child: EventEditScreen(evt),
            ),
          ),
        );
      },
    );
  }
}
