import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// Saját importok
import '../permission_service.dart'; // Igazítsd az útvonalat, ha máshol van!
import '../constants/theme.dart';
import 'home_page.dart';    // Igazítsd az útvonalat!

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
    bool isGranted = await Permission.systemAlertWindow.isGranted;

    if (firstTime && !isGranted) {
      _showRequestDialog();
    }
  }

  Future<void> _checkAfterReturning() async {
    if (_wentToSettings) {
      bool isGranted = await Permission.systemAlertWindow.isGranted;
      if (isGranted) {
        _showSuccessDialog();
      }
      _wentToSettings = false;
    }
  }

  void _showRequestDialog() {
    PermissionService.setDialogShown();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.accentRed),
            const SizedBox(width: 10),
            const Text("Fontos Engedély"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text("Üdvözöl az ÖsszHarang!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 10),
              Text("Ahhoz, hogy az alkalmazás igazi ébresztőóraként (vekkerként, riasztóként) tudjon működni, és a harangozás idején lezárt képernyőnél is teljes méretben megjelenjen, engedélyezned kell a 'Megjelenítés más alkalmazások felett' opciót."),
              SizedBox(height: 15),
              Text("Hol találod meg, ha a gomb nem visz oda automatikusan?", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(
                "• Samsung: Beállítások ➡️ Alkalmazások ➡️ Különleges alkalmazáshozzáférés ➡️ Megjelenés legfelül\n\n"
                    "• Xiaomi / Poco: Beállítások ➡️ Alkalmazások ➡️ Engedélykezelés ➡️ Egyéb engedélyek ➡️ 'Megjelenítés felugró ablakként'\n\n"
                    "• Egyéb Android: Beállítások ➡️ Alkalmazások ➡️ ÖsszHarang ➡️ Speciális ➡️ Megjelenítés más alkalmazások felett.",
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
        content: const Text("Sikeres beállítás! Az alkalmazás most már hibátlanul fog működni.", textAlign: TextAlign.center),
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