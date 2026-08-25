import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// --- PROVIDEREK IMPORTÁLÁSA ---
import 'providers/home_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/ebreszto_provider.dart';

// --- SAJÁT FÁJLOK IMPORTÁLÁSA ---
import 'constants/theme.dart';
import 'screens/permission_check_wrapper.dart'; // Az újonnan létrehozott fájl!

Future<void> main() async {
  // Inicializálások
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Alarm.init(showDebugLogs: true);

  runApp(
    // A HÁROM PROVIDER REGISZTRÁLÁSA
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => EbresztoProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppTheme.backgroundBase,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.backgroundBase,
            brightness: Brightness.dark,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppTheme.backgroundBase,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.borderDarkGreen, width: 1.5),
            ),
            titleTextStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            contentTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ),
        home: const PermissionCheckWrapper(),
      ),
    ),
  );
}