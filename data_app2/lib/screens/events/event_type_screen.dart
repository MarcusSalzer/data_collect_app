import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/fmt.dart';
import 'package:flutter/material.dart';

class EventTypeScreen extends StatelessWidget {
  final String name; // TODO: CHANGE TO EVENTTYPE?

  final AppState appState;
  late final Future<List<Event>> evtsF;

  EventTypeScreen(this.appState, {super.key, required this.name}) {
    evtsF = appState.db.getEventsFiltered(names: [name]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Column(
        children: [
          FutureBuilder(
            future: evtsF,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Text("Loading events...");
              }
              if (snap.hasError) {
                return Text(snap.error.toString());
              }
              final evts = snap.data;
              if (!snap.hasData || evts == null) {
                return Text("No data!");
              }

              final totTime = evts.fold(Duration.zero, (p, e) {
                final es = e.start;
                final ee = e.end;
                if (es != null && ee != null) {
                  final d = ee.difference(es);
                  return p + d;
                }
                return p;
              });

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("has ${evts.length} instances"),
                  Text("total time: ${Fmt.durationHM(totTime)}"),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}
