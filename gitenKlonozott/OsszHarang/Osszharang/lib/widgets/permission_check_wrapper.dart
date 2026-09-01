import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../permission_service.dart';
import '../constants/theme.dart';
import '../screens/home_page.dart';

class PermissionCheckWrapper extends StatefulWidget {
  const PermissionCheckWrapper({super.key});

  @override
  State<PermissionCheckWrapper> createState() => _PermissionCheckWrapperState();
}

class _PermissionCheckWrapperState extends State<PermissionCheckWrapper> with WidgetsBindingObserver {
  bool _wentToSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLogic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAfterReturning();
    }
  }

  Future<void> _initLogic() async {
    await [
      Permission.notification,
      Permission.scheduleExactAlarm,
    ].request();

    bool firstTime = await PermissionService.shouldShowDialog();
    bool isAlertGranted = Platform.isIOS ? true : await Permission.systemAlertWindow.isGranted;

    if (firstTime) {
      if (Platform.isAndroid && !isAlertGranted) {
        _showAndroidRequestDialog();
      } else if (Platform.isIOS) {
        _showIosInfoDialog();
      }
    }
  }

  Future<void> _checkAfterReturning() async {
    if (_wentToSettings && Platform.isAndroid) {
      bool isGranted = await Permission.systemAlertWindow.isGranted;
      if (isGranted) {
        _showSuccessDialog();
      }
      _wentToSettings = false;
    }
  }

  void _showIosInfoDialog() {
    PermissionService.setDialogShown();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.apple, color: Colors.white),
            SizedBox(width: 10),
            Text("iOS Működés"),
          ],
        ),
        content: const Text(
          "Az iPhone biztonsági szabályai (korlátozásai, előírásai) miatt az app nem tudja automatikusan feloldani a képernyőt.\n\nAmikor eljön a harangozás ideje, a hang a háttérből szólal meg, és egy értesítést (jelzést, üzenetet) kapsz. Koppints rá, hogy megnyíljon a harangozó felület!",
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.borderDarkGreen),
            child: const Text("MEGÉRTETTEM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAndroidRequestDialog() {
    PermissionService.setDialogShown();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.security, color: AppTheme.accentRed),
            SizedBox(width: 10),
            Text("Fontos Engedély"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text("Üdvözöl az ÖsszHarang!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 10),
              Text("Ahhoz, hogy az alkalmazás igazi ébresztőóraként (vekkerként, riasztóként) tudjon működni, és a harangozás idején lezárt képernyőnél is megjelenjen, engedélyezned kell a 'Megjelenítés más alkalmazások felett' opciót."),
              SizedBox(height: 15),
              Text("Hol találod meg?", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(
                "• Samsung: Beállítások ➡️ Alkalmazások ➡️ Különleges hozzáférés ➡️ Megjelenés legfelül\n\n"
                    "• Xiaomi: Beállítások ➡️ Alkalmazások ➡️ Engedélykezelés ➡️ Egyéb engedélyek ➡️ 'Felugró ablak'\n\n",
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("KÉSŐBB", style: TextStyle(color: AppTheme.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _wentToSettings = true;
              await Permission.systemAlertWindow.request();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text("BEÁLLÍTÁS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 50),
        content: const Text("Sikeres beállítás!", textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.borderDarkGreen),
              child: const Text("RENDBEN", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}