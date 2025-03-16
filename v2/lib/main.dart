import 'package:datacollectv2/db_service.dart';
import 'package:datacollectv2/screens/home_screen.dart';
import 'package:datacollectv2/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: settings.isDarkMode() ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
