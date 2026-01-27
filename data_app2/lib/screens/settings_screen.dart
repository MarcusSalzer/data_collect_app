import 'package:data_app2/app_state.dart';
import 'package:data_app2/screens/home_screen.dart';
import 'package:data_app2/screens/welcome_screen.dart';
import 'package:data_app2/style.dart';
import 'package:data_app2/util/dummy_data.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/util/enums.dart';
import 'package:data_app2/util/extensions.dart';
import 'package:data_app2/widgets/confirm_dialog.dart';
import 'package:data_app2/widgets/enum_dropdown_with_description.dart';
import 'package:data_app2/widgets/two_columns.dart';
import 'package:flutter/material.dart';
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AppState>(
        builder: (context, app, child) => Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TwoColumns(
                  flex: (3, 5),
                  rows: [
                    (
                      Text("Lowercase inputs"),
                      Switch(
                        value: app.autoLowerCase,
                        onChanged: (value) {
                          app.setAutoLowerCase(value);
                        },
                      ),
                    ),
                  ],
                ),
                EnumDropdownWithDescription<LogLevel>(
                  label: "Log level",
                  value: app.logLevel,
                  options: LogLevel.values,
                  onChanged: app.setLogLevel,
                  descriptionOf: (v) => v.description,
                ),
                EnumDropdownWithDescription<TextSearchMode>(
                  label: "Text search",
                  value: app.textSearchMode,
                  options: TextSearchMode.values,
                  onChanged: app.setSearchMode,
                  descriptionOf: (v) => v.description,
                ),
                EnumDropdownWithDescription<ColorSchemeMode>(
                  label: "Color Scheme",
                  value: app.prefs.colorSchemeMode,
                  options: ColorSchemeMode.values,
                  onChanged: (v) => app.setColorScheme(v),
                  descriptionOf: (v) => v.description,
                ),

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
                                      final cEvent = await app.db.events.deleteAll();
                                      final cType = await app.db.eventTypes.deleteAll();
                                      await app.db.prefs.clear();

                                      Logger.root.info("Deleted all data");

                                      // clear cache in repo
                                      app.evtTypeManager.clearCache();

                                      if (context.mounted) {
                                        simpleSnack(context, "deleted: $cEvent events, $cType event-types");
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
                            final recs = await dummyEvents(app);
                            app.db.events.putAll(recs.map((r) => r.toIsar()).toList());
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
