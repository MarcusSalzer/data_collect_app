import 'package:data_app2/app_state.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/screens/import_any_screen.dart';
import 'package:data_app2/screens/month_calendar_screen.dart';
import 'package:data_app2/screens/events/event_type_index_screen.dart';
import 'package:data_app2/screens/events/events_screen.dart';
import 'package:data_app2/screens/settings_screen.dart';
import 'package:data_app2/widgets/events_summary.dart';
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
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            EventsTodaySummaryFromAppState(),
            SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(builder: (context) => EventsScreen()),
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
                          builder: (context) => EventTypeIndexScreen(),
                        ),
                      );
                    },
                    label: Text("Manage events"),
                    icon: Icon(Icons.settings),
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: TextButton.icon(
                //     onPressed: () {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => TabularScreen(),
                //         ),
                //       );
                //     },
                //     label: Text("Tabular datasets"),
                //     icon: Icon(Icons.tab_unselected),
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MonthCalendarScreen(appState),
                        ),
                      );
                    },
                    label: Text("Calendar"),
                    icon: Icon(Icons.calendar_month),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    onPressed: () async {
                      final path = await pickSingleFile();
                      if (path == null) {
                        return;
                      }

                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ImportAnyScreen(path),
                          ),
                        );
                      }
                    },
                    label: Text("Import data"),
                    icon: Icon(Icons.download),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
