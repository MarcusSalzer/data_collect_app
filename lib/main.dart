import 'package:data_collector_app/data_provider.dart';
import 'package:data_collector_app/dataset_index_provider.dart';
import 'package:data_collector_app/screens/datasets_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => DatasetIndexProvider()..loadDatasetIndex()),
        ChangeNotifierProvider(create: (_) => DataProvider())
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  /// InheritedWidget style accessor to our State object.
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  // TODO DARKMODE BUGGY

  bool get isDarkmode => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: const MyHomePage(title: "Data collector"),
    );
  }

  void changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // NavigationRail navRail = NavigationRail(
    //   selectedIndex: selectedPage,
    //   extended: true,
    //   onDestinationSelected: (value) {
    //     setState(() {
    //       selectedPage = value;
    //     });
    //   },
    //   destinations: const [
    //     NavigationRailDestination(
    //       icon: Icon(Icons.add),
    //       label: Text("record data"),
    //     ),
    //     NavigationRailDestination(
    //       icon: Icon(Icons.list_alt),
    //       label: Text("Datasets"),
    //     ),
    //     NavigationRailDestination(
    //       icon: Icon(Icons.settings),
    //       label: Text("settings"),
    //     ),
    //   ],
    // );

    // return Scaffold(
    //   key: _scaffoldKey,
    //   appBar: _appBars[selectedPage],
    //   body: SafeArea(
    //     child: Row(
    //       children: [
    //         navRail,
    //         Expanded(
    //           child: _pages[selectedPage],
    //         ),
    //       ],
    //     ),
    //   ),
    // );

    // Start at the datasets list
    return const DatasetsScreen();
  }
}
