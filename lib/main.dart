import 'package:data_collector_app/dataset_index_provider.dart';
import 'package:data_collector_app/screens/input_screen_single.dart';
import 'package:data_collector_app/screens/datasets_screen.dart';
import 'package:data_collector_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (BuildContext context) => DatasetIndexProvider()..loadDatasetIndex(),
      child: const MyApp(),
    ),
  );
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
  static final List<Widget> _pages = [
    const InputScreen(),
    const DatasetsScreen(),
    const SettingsScreen(),
  ];

  static final List<PreferredSizeWidget> _appBars = [
    const InputAppBar(),
    const DatasetsAppBar(),
    const SettingsAppBar(),
  ];

  int selectedPage = 1;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

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

    assert(_appBars.length == _pages.length, "Need appBars for all pages");
    assert(selectedPage < _pages.length);

    return Scaffold(
      key: _scaffoldKey,
      appBar: _appBars[selectedPage],
      body: SafeArea(
        child: Row(
          children: [
            navRail,
            Expanded(
              child: _pages[selectedPage],
            ),
          ],
        ),
      ),
    );
  }
}
