import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Saját importok (igazítsd az útvonalakat a projektedhez!)
import '../constants/theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_card.dart';
import '../widgets/permission_row.dart';

class BeallitasokPage extends StatefulWidget {
  const BeallitasokPage({Key? key}) : super(key: key);

  @override
  State<BeallitasokPage> createState() => _BeallitasokPageState();
}

class _BeallitasokPageState extends State<BeallitasokPage> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A provider már a konstruktorában meghívja a loadSettings-t és checkPermissions-t!
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ha visszatérünk az appba, frissítjük az engedélyeket a providerben
      context.read<SettingsProvider>().checkPermissions();
    }
  }

  // Ez marad a UI-ban, mert dialógust (vizuális elemet) dob fel
  Future<bool?> _showDisableConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2328),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Biztosan kikapcsolod?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Az alkalmazás legfőbb célja a június 4-i közös harangozás. Kikapcsolt állapotban nem fogsz kapni értesítést az évfordulókor.",
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("MÉGSEM", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("KIKAPCSOLÁS", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleJun4Toggle(bool value, SettingsProvider provider) async {
    if (!value) {
      final confirm = await _showDisableConfirmation();
      if (confirm != true) return;
    }
    provider.toggleJun4(value);
  }

  @override
  Widget build(BuildContext context) {
    // Rácsatlakozunk a providerre
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBase,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/hatter.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 15.0, left: 15.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Text("Vissza", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
                  child: Text("Beállítások", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      SettingsCard(
                        icon: Icons.notifications_active,
                        iconColor: Colors.orangeAccent,
                        title: "Június 4-i harangozás",
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("Automatikus harangozás", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text("Június 4-én 16:32-kor (CET)", style: TextStyle(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                            CupertinoSwitch(
                              value: provider.isJun4Active,
                              activeColor: Colors.cyanAccent.shade400,
                              onChanged: (val) => _handleJun4Toggle(val, provider),
                            ),
                          ],
                        ),
                      ),

                      SettingsCard(
                        icon: Icons.wb_sunny_outlined,
                        iconColor: Colors.amberAccent,
                        title: "Minden nap déli harangszó",
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text("Déli harangozás", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                    SizedBox(height: 4),
                                    Text("Minden nap pontosan 12:00-kor", style: TextStyle(color: Colors.white54, fontSize: 13)),
                                  ],
                                ),
                                CupertinoSwitch(
                                  value: provider.isNoonBellActive,
                                  activeColor: Colors.cyanAccent.shade400,
                                  onChanged: provider.toggleNoonBell,
                                ),
                              ],
                            ),
                            if (provider.isNoonBellActive) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 15.0),
                                child: Divider(color: Colors.white10, thickness: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Harangozás hossza", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                  Text("${provider.noonDurationSeconds} mp", style: TextStyle(color: Colors.cyanAccent.shade400, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Slider(
                                value: provider.noonDurationSeconds.toDouble(),
                                min: 2,
                                max: 300,
                                divisions: 298,
                                activeColor: Colors.cyanAccent.shade400,
                                inactiveColor: Colors.white10,
                                onChanged: (val) {
                                  // Ideiglenes állapotfrissítés a csúszkán vizuálisan, mentés onChangeEnd-nél
                                  provider.saveNoonDuration(val.toInt());
                                },
                              ),
                            ]
                          ],
                        ),
                      ),

                      SettingsCard(
                        icon: Icons.volume_up,
                        iconColor: Colors.greenAccent,
                        title: "Hangbeállítások",
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Rezgés harangozáskor", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                CupertinoSwitch(
                                  value: provider.vibration,
                                  activeColor: Colors.cyanAccent.shade400,
                                  onChanged: provider.saveVibration,
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Row(
                              children: [
                                const Icon(Icons.volume_down, color: Colors.white54, size: 20),
                                Expanded(
                                  child: Slider(
                                    value: provider.volume,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: Colors.cyanAccent.shade400,
                                    inactiveColor: Colors.white10,
                                    onChanged: provider.saveVolume,
                                  ),
                                ),
                                Icon(Icons.volume_up, color: Colors.cyanAccent.shade400, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SettingsCard(
                        icon: Icons.language,
                        iconColor: Colors.lightBlueAccent,
                        title: "Időzóna információ",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              textAlign: TextAlign.justify,
                              text: const TextSpan(
                                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                                children: [
                                  TextSpan(text: "A harangozás minden évben "),
                                  TextSpan(
                                    text: "magyar idő szerint 16:32-kor ",
                                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: "(CET/CEST) szólal meg, függetlenül attól, hogy a világon hol tartózkodik a felhasználó."),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Például New Yorkban délelőtt 10:32-kor (EST), Londonban 15:32-kor (GMT+1), Tokióban 23:32-kor (JST) szólal meg.",
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),

                      SettingsCard(
                        icon: Icons.security,
                        iconColor: Colors.purpleAccent,
                        title: "Rendszerengedélyek",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Az alkalmazás pontos működéséhez az alábbi engedélyek szükségesek.",
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 20),

                            PermissionRow(
                              title: "Értesítések küldése",
                              description: "A háttérben futó emlékeztetők megjelenítése.",
                              isGranted: provider.isNotificationGranted,
                              onRequest: () async {
                                await Permission.notification.request();
                                provider.checkPermissions();
                              },
                            ),
                            const Divider(color: Colors.white10, height: 20),

                            if (Platform.isAndroid) ...[
                              PermissionRow(
                                title: "Pontos időzítés",
                                description: "A harangozás percre pontos indításához.",
                                isGranted: provider.isExactAlarmGranted,
                                onRequest: () async {
                                  await Permission.scheduleExactAlarm.request();
                                  provider.checkPermissions();
                                },
                              ),
                              const Divider(color: Colors.white10, height: 20),

                              PermissionRow(
                                title: "Megjelenítés legfelül",
                                description: "A riasztás megjelenítéséhez lezárt képernyőnél is.",
                                isGranted: provider.isAlertWindowGranted,
                                onRequest: () async {
                                  await Permission.systemAlertWindow.request();
                                  provider.checkPermissions();
                                },
                              ),
                              const SizedBox(height: 15),
                              if (!provider.isAlertWindowGranted)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: const Text(
                                    "Ha a gomb nem működik:\n"
                                        "Samsung: Beállítások -> Alkalmazások -> Különleges hozzáférés -> Megjelenés legfelül\n"
                                        "Xiaomi: Beállítások -> Alkalmazások -> Engedélykezelés -> Egyéb engedélyek -> 'Felugró ablak'",
                                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                                  ),
                                ),
                            ] else if (Platform.isIOS) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Text(
                                  "Az iPhone biztonsági szabályai miatt az ébresztő nem ugrik fel automatikusan a zárolt képernyőn. A harangozás a háttérben szólal meg, és az értesítésre koppintva tudod megnyitni a felületet.",
                                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}