import 'package:data_app2/db_service.dart';
import 'package:data_app2/event_stats_compute.dart';
import 'package:data_app2/fmt.dart';
import 'package:data_app2/plots.dart';
import 'package:data_app2/widgets/events_summary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DayViewModel extends ChangeNotifier {
  List<Event> _events = [];

  List<MapEntry<String, Duration>> tpe = [];
  List<Event> get events => _events;

  DayViewModel({List<Event>? events}) {
    _events = events ?? [];
    // tpe = timePerEvent(_events, limit: 16);
  }
}

class DayScreen extends StatefulWidget {
  final DateTime dt;

  final List<Event>? events;
  const DayScreen(this.dt, {super.key, this.events});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  late DateTime dt;
  @override
  void initState() {
    dt = widget.dt;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DayViewModel(events: widget.events),
      child: Scaffold(
        appBar: AppBar(
          title: Text(Fmt.verboseDate(dt)),
        ),
        body: Consumer<DayViewModel>(
          builder: (context, value, child) {
            if (value.events.isEmpty) {
              return Center(
                child: Text("No events"),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                EventsSummary(
                  title: Fmt.verboseDate(dt),
                  tpe: value.tpe,
                  colors: Colors.primaries,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: EventPieChart(
                      timings: value.tpe,
                      colors: Colors.primaries,
                      nTitles: 8,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
