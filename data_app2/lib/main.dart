import 'package:data_app2/db_service.dart';
import 'package:data_app2/screens/home_screen.dart';
import 'package:data_app2/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

void main() async {
  // note: we need the DB to be ready to read user prefs when starting app
  WidgetsFlutterBinding.ensureInitialized();
  // prevent landscape mode (no use for landscape now)
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  developer.log("App starting...");
  runApp(MyApp(service: DBService(await initIsar())));
}

class MyApp extends StatelessWidget {
  final DBService service;

  const MyApp({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(service),
      child: Consumer<AppState>(
        builder: (context, settings, child) => MaterialApp(
          title: 'data collect',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.cyan, brightness: Brightness.dark),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
