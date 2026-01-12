import 'package:data_app2/app_state.dart';
import 'package:data_app2/view_models/event_create_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventsStatsScreen extends StatelessWidget {
  const EventsStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text("Stats")),
      body: ChangeNotifierProvider<EventCreateViewVM>(
        create: (_) => EventCreateViewVM(appState),
        child: EventsStatsView(),
      ),
    );
  }
}

class EventsStatsView extends StatelessWidget {
  const EventsStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    // final app = Provider.of<AppState>(context);
    return Consumer<EventCreateViewVM>(
      builder: (context, evm, child) {
        if (evm.isLoading) {
          return Center(child: Text("Loading events..."));
        }

        return Center(child: Text("not implemented"));

        // final now = DateTime.now();
        // final startR = now.subtract(Duration(days: 7));
        // final filtered =
        //     evm.events.where((e) => e.start?.isAfter(startR) ?? false);

        // final timings = timePerEvent(filtered, limit: 16);
        // final colors = List.generate(timings.length,
        //     (index) => Colors.primaries[index % Colors.primaries.length]);

        // return Column(
        //   children: [
        //     Text("Last week: ${filtered.length} events"),
        //     Expanded(
        //       child: EventPieChart(
        //           timings: timings
        //               .map((e) =>
        //                   MapEntry(app.eventName(e.key) ?? "unknown", e.value))
        //               .toList(),
        //           colors: colors),
        //     )
        //   ],
        // );
      },
    );
  }
}
