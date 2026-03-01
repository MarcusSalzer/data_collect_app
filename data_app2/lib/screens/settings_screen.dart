import 'package:data_app2/app_state.dart';
import 'package:data_app2/daily_evt_summary_service.dart';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/screens/color_spread_screen.dart';
import 'package:data_app2/screens/daily_fingerprint_screen.dart';
import 'package:data_app2/screens/home_screen.dart';
import 'package:data_app2/screens/welcome_screen.dart';
import 'package:data_app2/style.dart';
import 'package:data_app2/util/dummy_data.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/util/fmt.dart';
import 'package:data_app2/widgets/confirm_dialog.dart';
import 'package:data_app2/widgets/enum_dropdown_with_description.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

class EnumDropdown<E extends Enum> extends StatelessWidget {
  final E initialValue;
  final List<E> options;

  final void Function(E) onChanged;

  const EnumDropdown({super.key, required this.initialValue, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<E>(
      initialValue: initialValue,
      items: options.map((opt) {
        return DropdownMenuItem(value: opt, child: Text(opt.name.capitalized));
      }).toList(),
      onChanged: (choice) {
        if (choice != null) {
          onChanged(choice);
        }
      },
      decoration: InputDecoration(border: OutlineInputBorder()),
    );
  }
}

class LogLevelDropdown extends StatelessWidget {
  final AppState _app;

  const LogLevelDropdown(this._app, {super.key});

  @override
  Widget build(BuildContext context) {
    final currentLevel = _app.logLevel;
    return ConstrainedBox(
      constraints: BoxConstraints.loose(Size.fromWidth(300)),
      child: DropdownButtonFormField<LogLevel>(
        initialValue: currentLevel,
        items: LogLevel.values.map((level) {
          return DropdownMenuItem(
            value: level,
            child: Column(
              children: [
                Text(level.name.capitalized),
                // Text(
                //   "Is there space for adescriptions",
                //   style: TextStyle(fontSize: 10),
                // ),
              ],
            ),
          );
        }).toList(),
        onChanged: (newLevel) {
          if (newLevel != null) {
            _app.setLogLevel(newLevel);
          }
        },
      ),
    );
  }
}

class _PrefsForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prefs = context.select<AppState, AppPrefs>((a) => a.prefs);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text("Behavior", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        SettingContainer(
          "Lowercase inputs",
          "Automatically make inputs lowercase.",
          child: Switch(value: prefs.autoLowerCase, onChanged: context.read<AppState>().setAutoLowerCase),
        ),
        EnumDropdownWithDescription<LogLevel>(
          label: "Log level",
          value: prefs.logLevel,
          options: LogLevel.values,
          onChanged: context.read<AppState>().setLogLevel,
          descriptionOf: (v) => v.description,
        ),
        EnumDropdownWithDescription<TextSearchMode>(
          label: "Text search",
          value: prefs.textSearchMode,
          options: TextSearchMode.values,
          onChanged: context.read<AppState>().setSearchMode,
          descriptionOf: (v) => v.description,
        ),
        EnumDropdownWithDescription<SummaryMode>(
          label: "Default summary mode",
          value: prefs.summaryMode,
          options: SummaryMode.values,
          onChanged: context.read<AppState>().setTodaySummaryMode,
          descriptionOf: (v) => v.description,
        ),
        SettingContainer(
          "Day starts at",
          "Timestamps between local midnight and the provided time will count to the previous day.",
          child: DropdownButton<int>(
            value: prefs.dayStartsH,
            items: List.generate(
              6,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(Fmt.durationHm(Duration(hours: i))),
              ),
            ),
            onChanged: (v) => context.read<AppState>().updatePrefs(prefs.copyWith(dayStartsH: v)),
          ),
        ),
        Text("Aesthetics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        EnumDropdownWithDescription<ColorSchemeMode>(
          label: "Color Scheme",
          value: prefs.colorSchemeMode,
          options: ColorSchemeMode.values,
          onChanged: (v) => context.read<AppState>().setColorScheme(v),
          descriptionOf: (v) => v.description,
        ),
        SettingContainer(
          "Color spread",
          "Spread colors in categories",
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ColorSpreadScreen(
                    initVal: prefs.colorSpread,
                    saveAction: (v) async {
                      await context.read<AppState>().updatePrefs(prefs.copyWith(colorSpread: v));
                      return true;
                    },
                  ),
                ),
              );
            },
            child: Text(NumberFormat.decimalPercentPattern(decimalDigits: 0).format(prefs.colorSpread)),
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PrefsForm(),
              SizedBox(height: 20),
              Text("Info", style: TextStyle(fontSize: 20)),
              Wrap(
                spacing: 8,
                children: [
                  Text("Database stored in:"),
                  Text(app.db.dbFolder.toString(), style: filePathText),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  Text("User accessible data:"),
                  Text(app.userStoreDir.path, style: filePathText),
                ],
              ),
              SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DailySummaryScreen(db: app.db, summaryService: DailyEvtSummaryService(app.evtTypeManager)),
                    ),
                  );
                },
                label: Text("Daily summary fingerprint"),
              ),
              TextButton.icon(
                onPressed: () {
                  showLicensePage(context: context);
                },
                label: Text("Licenses"),
              ),

              HomeNavLink("Show welcome screen", null, builder: (context) => WelcomeScreen()),
              SizedBox(height: 20),

              Text("Dangerous", style: TextStyle(fontSize: 20)),
              SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        title: Text("are you sure?"),
                        titlePadding: EdgeInsets.all(20),
                        children: [
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("cancel"),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    // delete all from DB
                                    final app = context.read<AppState>();

                                    final cEvent = await app.db.evts.forceDeleteAll();
                                    final cType = await app.db.evtTypes.forceDeleteAll();
                                    final cCat = await app.db.evtCats.forceDeleteAll();

                                    await app.clearPrefs();

                                    Logger.root.info("Deleted all data");

                                    // clear cache in repo
                                    app.evtTypeManager.clearCache();

                                    if (context.mounted) {
                                      simpleSnack(
                                        context,
                                        "deleted: $cEvent events, $cType event-types, $cCat event-categories",
                                      );
                                    }
                                  },
                                  label: Text("delete", style: TextStyle(color: Colors.red)),
                                  icon: Icon(Icons.warning, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                label: Text("delete all"),
                icon: Icon(Icons.delete_forever),
              ),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ConfirmDialog(
                        title: "Generate dummy data",
                        action: () async {
                          final app = context.read<AppState>();
                          final recs = await dummyEvents(app);
                          await app.db.evts.createAll(recs);
                          Logger.root.warning("generated dummy data");
                          if (context.mounted) {
                            simpleSnack(context, "open events to refresh!");
                          }
                        },
                      );
                    },
                  );
                },
                label: Text("Generate dummy data"),
                icon: Icon(Icons.shuffle),
              ),
              // extra padding at bottom of scroll
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
