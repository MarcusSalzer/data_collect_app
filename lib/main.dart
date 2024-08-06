import 'package:data_collector_app/screens/input_screen_single.dart';
import 'package:data_collector_app/screens/datasets_screen.dart';
import 'package:data_collector_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: "Data collector"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedPage = 0;

  @override
  Widget build(BuildContext context) {
    NavigationRail navRail = NavigationRail(
      selectedIndex: selectedPage,
      extended: true,
      onDestinationSelected: (value) {
        setState(() {
          selectedPage = value;
        });
      },
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.add),
          label: Text("record data"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.list_alt),
          label: Text("Datasets"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text("settings"),
        ),
      ],
    );

    Widget page; // choose based on selection
    switch (selectedPage) {
      case 0:
        page = const InputScreen();
        break;
      case 1:
        page = const DatasetsScreen();
        break;
      case 2:
        page = const SettingsScreen();
        break;
      default:
        throw UnimplementedError("no page for: $selectedPage");
    }

    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   title: Text(widget.title),
      // ),
      body: SafeArea(
        child: Row(
          children: [
            navRail,
            Expanded(
              child: page,
            ),
          ],
        ),
      ),
    );
  }
}
