import 'package:data_app2/screens/events_screen.dart';
import 'package:data_app2/screens/settings_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: Text("hej"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Datasets"),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => EventsScreen()));
                },
                label: Text("Events"),
                icon: Icon(Icons.timelapse),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
