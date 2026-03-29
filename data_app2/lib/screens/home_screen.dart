import 'package:data_app2/app_state.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/dialogs/import_something_dialog.dart';
import 'package:data_app2/permission_manager.dart';
import 'package:data_app2/screens/events/type_cat_index_screen.dart';
import 'package:data_app2/screens/month_calendar_screen.dart';
import 'package:data_app2/screens/events/events_screen.dart';
import 'package:data_app2/screens/settings_screen.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/view_models/today_summary_vm.dart';
import 'package:data_app2/widgets/today_summary_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Subscribe to global prefs
    final prefs = context.select<AppState, AppPrefs>((a) => a.prefs);

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
        child: ChangeNotifierProvider<TodaySummaryDisplayVm>(
          create: (createCtx) {
            final app = createCtx.read<AppState>();
            return TodaySummaryDisplayVm(
              Duration(hours: prefs.dayStartsH),
              app.db,
              app.evtTypeManager,
              prefs.colorSpread,
              prefs.summaryMode,
            )..load();
          },
          builder: (context, _) => Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TodaySummaryDisplay(), // listens to its own provider
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
                      context.read<TodaySummaryDisplayVm>().load();
                    },
                  ),
                  // --- A single screen for showing event types and categories.
                  HomeNavLink(
                    "My events",
                    Icons.abc,
                    builder: (context) => EventTypeCatIndexScreen(),
                  ),

                  HomeNavLink("Calendar", Icons.calendar_month, builder: (context) => MonthCalendarScreen()),
                  // button for dialog -> import screen
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// For navigating to a new screen
class HomeNavLink extends StatelessWidget {
  final String _name;
  final IconData? _icon;
  final Widget Function(BuildContext) builder;
  final Function(dynamic completion)? returnCallback;

  const HomeNavLink(this._name, this._icon, {required this.builder, this.returnCallback, super.key});

  @override
  Widget build(BuildContext context) {
    void action() {
      Navigator.of(context).push(MaterialPageRoute(builder: builder)).then(returnCallback ?? (_) => {});
    }

    if (_icon != null) {
      return TextButton.icon(onPressed: action, label: Text(_name), icon: Icon(_icon));
    } else {
      return TextButton(onPressed: action, child: Text(_name));
    }
  }
}
