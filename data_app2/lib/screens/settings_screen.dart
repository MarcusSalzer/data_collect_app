import 'package:data_app2/app_state.dart';
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
    AppState appState = Provider.of<AppState>(context, listen: false);
    return Column(
      children: [
        Text("settings"),
        Row(
          children: [
            Text("Dark mode"),
            Switch(
              value: appState.isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  appState.setDarkMode(value);
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
                value: appState.normStrip,
                onChanged: (bool? value) {
                  setState(() {
                    appState.setNormStrip(value ?? false);
                  });
                })
          ],
        ),
        Row(
          children: [
            Text("Lowercase"),
            Checkbox(
              value: appState.normCase,
              onChanged: (bool? value) {
                setState(() {
                  appState.setNormCase(value ?? false);
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
                              final c = await appState.db.deleteAllEvents();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("deleted $c events"),
                                  ),
                                );
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
        )
      ],
    );
  }
}
