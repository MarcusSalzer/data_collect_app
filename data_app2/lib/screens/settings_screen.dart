import 'package:data_app2/app_state.dart';
import 'package:data_app2/dummy_data.dart';
import 'package:data_app2/util.dart';
import 'package:data_app2/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: SettingsMenu(),
      ),
    );
  }
}

class SettingsMenu extends StatefulWidget {
  const SettingsMenu({
    super.key,
  });

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  @override
  Widget build(BuildContext context) {
    AppState app = Provider.of<AppState>(context, listen: false);
    return Column(
      children: [
        Text("settings"),
        Row(
          children: [
            Text("Dark mode"),
            Switch(
              value: app.isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  app.setDarkMode(value);
                });
              },
            ),
          ],
        ),
        Text(
          "input normalization",
          style: TextStyle(fontSize: 20),
        ),
        Row(
          children: [
            Text("Strip leading/trailing whitespace"),
            Checkbox(
                value: app.normStrip,
                onChanged: (bool? value) {
                  setState(() {
                    app.setNormStrip(value ?? false);
                  });
                })
          ],
        ),
        Row(
          children: [
            Text("Lowercase"),
            Checkbox(
              value: app.normCase,
              onChanged: (bool? value) {
                setState(() {
                  app.setNormCase(value ?? false);
                });
              },
            ),
          ],
        ),
        Text("Dangerous", style: TextStyle(fontSize: 20)),
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
                            child: Text(
                              "cancel",
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              final c = await app.db.deleteAllEvents();
                              if (context.mounted) {
                                simpleSnack(context, "deleted $c events");
                              }
                            },
                            label: Text(
                              "delete",
                              style: TextStyle(color: Colors.red),
                            ),
                            icon: Icon(
                              Icons.warning,
                              color: Colors.red,
                            ),
                          )
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
                    app.db.importEventsDB(recs);
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
        )
      ],
    );
  }
}
