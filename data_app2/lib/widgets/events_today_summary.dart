// a small widget for seeing todays events

import 'package:data_app2/app_state.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventsTodaySummary extends StatefulWidget {
  const EventsTodaySummary({super.key});

  @override
  State<EventsTodaySummary> createState() => _EventsTodaySummaryState();
}

class _EventsTodaySummaryState extends State<EventsTodaySummary> {
  Future<List<Event>>? _futureEvents;

  void _loadEvents() {
    final appState = Provider.of<AppState>(context, listen: false);
    final now = DateTime.now();
    _futureEvents = appState.db.getEventsFiltered(
      earliest: now.startOfDay,
      latest: now.startOfDay.add(Duration(days: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _futureEvents = null;
    _loadEvents();
    final now = DateTime.now();
    final form = DateFormat("yy-MM-dd");

    return FutureBuilder(
      future: _futureEvents,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text("laoding");
        } else if (snap.hasError) {
          return Text('Error: ${snap.error}');
        } else if (!snap.hasData) {
          return const Text('No events today.');
        } else if (snap.data!.isEmpty) {
          return Text("empty");
        }

        final eventList = snap.data;

        if (eventList == null) {
          return Text("null");
        }

        return Column(
          children: [
            Text(
                "Events betwen ${form.format(now.startOfDay)} and ${form.format(now.startOfDay.add(Duration(days: 1)))}: ${eventList.length} ")
          ],
        );
      },
    );
  }
}

class FutureBuilderExample extends StatefulWidget {
  const FutureBuilderExample({super.key});

  @override
  State<FutureBuilderExample> createState() => _FutureBuilderExampleState();
}

class _FutureBuilderExampleState extends State<FutureBuilderExample> {
  final Future<String> _calculation = Future<String>.delayed(
    const Duration(seconds: 2),
    () => 'Data Loaded',
  );

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.displayMedium!,
      textAlign: TextAlign.center,
      child: FutureBuilder<String>(
        future: _calculation, // a previously-obtained Future<String> or null
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            children = <Widget>[
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 60),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Result: ${snapshot.data}'),
              ),
            ];
          } else if (snapshot.hasError) {
            children = <Widget>[
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              ),
            ];
          } else {
            children = const <Widget>[
              SizedBox(
                  width: 60, height: 60, child: CircularProgressIndicator()),
              Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Awaiting result...')),
            ];
          }
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: children),
          );
        },
      ),
    );
  }
}

class ASCsummary extends StatelessWidget {
  const ASCsummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, value, child) {
        final s = value.todaySummary;
        if (s == null) {
          return Text("loading todaySummary");
        }
        return Column(
          children: [
            Text("Today"),
            Text(
              s.data,
              style: TextStyle(fontSize: 20),
            ),
          ],
        );
      },
    );
  }
}
