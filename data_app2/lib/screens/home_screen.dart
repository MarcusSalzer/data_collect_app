import 'package:data_app2/app_state.dart';
import 'package:data_app2/dialogs/import_something_dialog.dart';
import 'package:data_app2/permission_manager.dart';
import 'package:data_app2/screens/color_demo_page.dart';
import 'package:data_app2/screens/month_calendar_screen.dart';
import 'package:data_app2/screens/events/event_type_index_screen.dart';
import 'package:data_app2/screens/events/events_screen.dart';
import 'package:data_app2/screens/settings_screen.dart';
import 'package:data_app2/util.dart';
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
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettingsScreen()));
            },
            icon: Icon(Icons.settings),
          ),
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
              spacing: 20,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeNavLink(
                  "Events",
                  Icons.timelapse,
                  builder: (context) => EventsScreen(),
                  returnCallback: (completion) {
                    // after visiting this route, todays data might have updated
                    appState.refreshSummary();
                  },
                ),
                HomeNavLink(
                  "Event types",
                  Icons.category,
                  builder: (context) => EventTypeIndexScreen(),
                  returnCallback: (completion) {
                    // after visiting this route, todays data might have updated
                    appState.refreshSummary();
                  },
                ),
                HomeNavLink("Calendar", Icons.calendar_month, builder: (context) => MonthCalendarScreen(appState)),

                TextButton.icon(
                  onPressed: () async {
                    if (await PermissionManager.requestStorage() && context.mounted) {
                      await showImportSomethingDialog(context);
                    } else if (context.mounted) {
                      simpleSnack(context, "needs storage permission");
                    }
                  },
                  label: Text("Import data"),
                  icon: Icon(Icons.download),
                ),

                HomeNavLink("Color demo", Icons.palette, builder: (context) => ColorDemoPage()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// For navigating to a new screen
class HomeNavLink extends StatelessWidget {
  final String _name;
  final IconData _icon;
  final Widget Function(BuildContext) builder;
  final Function(dynamic completion)? returnCallback;

  const HomeNavLink(this._name, this._icon, {required this.builder, this.returnCallback, super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: builder)).then(returnCallback ?? (_) => {});
      },
      label: Text(_name),
      icon: Icon(_icon),
    );
  }
}
