import 'package:data_app2/app_state.dart' show AppState;
import 'package:data_app2/db_service.dart';
import 'package:flutter/material.dart';

class EventsTimeSummaryScreen extends StatelessWidget {
  late final Future<List<Event>> filteredEventsFuture;

  final AppState appState;
  EventsTimeSummaryScreen({super.key, required this.appState}) {
    filteredEventsFuture = appState.db.getEventsFiltered();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Events Time Sumary")),
      body: Column(
        children: [
          Center(
            child: Text("This is the events time sumary screen"),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Here"),
              Text("Goes"),
              Text("something"),
            ],
          ),
          FutureBuilder(
            future: filteredEventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData) {
                return Text("filtered events: ${snapshot.data!.length}");
              }
              return Text("No data available");
            },
          )
        ],
      ),
    );
  }
}
