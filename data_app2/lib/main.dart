import 'dart:io';
import 'package:data_app2/data/app_prefs.dart';
import 'package:data_app2/db_service.dart';
import 'package:data_app2/io.dart';
import 'package:data_app2/isar_models.dart';
import 'package:data_app2/prefs_io.dart';
import 'package:data_app2/screens/home_screen.dart';
import 'package:data_app2/app_state.dart';
import 'package:data_app2/screens/welcome_screen.dart';
import 'package:data_app2/style.dart';
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
    // Simple logging, not perfectly thread safe.
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

  try {
    final prefsFile = await PrefsIo.defaultPrefsFile;

    final prefs = await PrefsIo.load(prefsFile);

    if (prefs == null) {
      Logger.root.info("No prefs found");
      // first startup, store default prefs
      PrefsIo.store(AppPrefs(), prefsFile);
    }
    final db = DBService(await initIsar(prefsFile.parent));
    await db.ensureReady();

    runApp(
      MyApp(
        // Need a db. stored next to prefs
        db: db,
        prefs: prefs ?? AppPrefs(),
        userStoreDir: await defaultUserStoreDir(),
        // No prefs -> first startup
        showWelcome: prefs == null,
        prefsFile: prefsFile,
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

  final File prefsFile;

  const MyApp({
    super.key,
    required this.db,
    required this.prefs,
    required this.prefsFile,
    required this.userStoreDir,
    required this.showWelcome,
  });

  @override
  Widget build(BuildContext context) {
    // Global state and methods in AppState.
    // Use select/watch/read, and maybe Consumer where appropriate.
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(db, prefs, userStoreDir, prefsFile),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'data collect app',
            theme: context.select<AppState, ColorSchemeMode>((a) => a.prefs.colorSchemeMode).theme,
            // Start at "welcome" or "home"
            home: showWelcome ? const WelcomeScreen() : const HomeScreen(),
          );
        },
      ),
    );
  }
}
