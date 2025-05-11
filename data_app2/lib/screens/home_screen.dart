import 'package:data_app2/app_state.dart';
import 'package:data_app2/screens/event_manager_screen.dart';
import 'package:data_app2/screens/events_screen.dart';
import 'package:data_app2/screens/events_stats_screen.dart';
import 'package:data_app2/screens/events_time_summary_screen.dart';
import 'package:data_app2/screens/settings_screen.dart';
import 'package:data_app2/screens/tabular_screen.dart';
import 'package:data_app2/widgets/events_today_summary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
              icon: Icon(Icons.settings)),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Data app"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              flex: 1,
              child: ASCsummary(),
            ),
            SizedBox(height: 20),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                              builder: (context) => EventsScreen()),
                        )
                            .then((completion) {
                          // after visiting this route, todays data might have updated
                          appState.refreshSummary();
                        });
                      },
                      label: Text("Events"),
                      icon: Icon(Icons.timelapse),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EventsStatsScreen(),
                          ),
                        );
                      },
                      label: Text("Stats"),
                      icon: Icon(Icons.stacked_bar_chart),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EventManagerScreen(),
                          ),
                        );
                      },
                      label: Text("Manage events"),
                      icon: Icon(Icons.settings),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TabularScreen(),
                          ),
                        );
                      },
                      label: Text("Tabular datasets"),
                      icon: Icon(Icons.tab_unselected),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
