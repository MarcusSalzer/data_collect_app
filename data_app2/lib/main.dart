import 'dart:io';

import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/screens/home_screen.dart';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  // --- Init Logging
  final logFile = await defaultLogFile();
  Logger.root.level = Level.ALL; // temporary default
  Logger.root.onRecord.listen((record) {
    final msg = '${record.level.name}: ${record.time}: ${record.message}';
    logFile.writeAsString("$msg\n", mode: FileMode.append);
  });

  // note: we need the DB to be ready to read user prefs when starting app
  WidgetsFlutterBinding.ensureInitialized();
  // prevent landscape mode (no use for landscape now)
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // maybe we can log?
  try {
    Logger.root.info("app starting");
  } catch (e) {
    // oops, cannot log there
  }

  // before doing anything we need the DB-service
  try {
    final db = DBService(await initIsar());

    // stored preferences or defaults
    final loadedPrefs = await db.prefs.load();
    final prefs = AppPrefs.fromIsar(loadedPrefs);
    if (loadedPrefs == null) {
      // first startup, store default prefs
      await db.prefs.store(prefs.toIsar());
    }
    runApp(
      MyApp(
        db: db,
        prefs: prefs,
        userStoreDir: await defaultStoreDir(),
        // No prefs -> first startup
        showWelcome: loadedPrefs == null,
      ),
    );
  } on MissingPlatformDirectoryException catch (e) {
    runApp(StartupErrorApp("Could not find the expected storage directory. $e"));
  } catch (e) {
    runApp(StartupErrorApp("Unexpected error. $e"));
  }
}

/// If the app fails to start we can show this
class StartupErrorApp extends StatelessWidget {
  final String msg;

  const StartupErrorApp(this.msg, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: Text(msg))),
    );
  }
}

class MyApp extends StatelessWidget {
  final DBService db;

  final AppPrefs prefs;

  final Directory userStoreDir;

  final bool showWelcome;

  const MyApp({
    super.key,
    required this.db,
    required this.prefs,
    required this.userStoreDir,
    required this.showWelcome,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(db, prefs, userStoreDir),
      child: Consumer<AppState>(
        builder: (context, app, child) => MaterialApp(
          title: 'data collect',
          theme: app.prefs.colorSchemeMode.theme,
          // Start at "welcome" or "home"
          home: showWelcome ? const WelcomeScreen() : const HomeScreen(),
        ),
      ),
    );
  }
}
