import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

// Saját fájlok importja
import 'constants/theme.dart';

class BeallitasokPage extends StatefulWidget {
  const BeallitasokPage({Key? key}) : super(key: key);

  @override
  State<BeallitasokPage> createState() => _BeallitasokPageState();
}

class _BeallitasokPageState extends State<BeallitasokPage> with WidgetsBindingObserver {
  // --- BEÁLLÍTÁS VÁLTOZÓK ---
  bool _jun4 = true;
  bool _noonBell = false;
  int _noonDurationSeconds = 60; // ÚJ: Déli harangozás hossza
  bool _vibration = true;
  double _volume = 0.8;

  // --- ENGEDÉLY ÁLLAPOTOK ---
  bool _isAlertWindowGranted = false;
  bool _isNotificationGranted = false;
  bool _isExactAlarmGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final alertStatus = await Permission.systemAlertWindow.isGranted;
    final notifStatus = await Permission.notification.isGranted;
    final exactStatus = await Permission.scheduleExactAlarm.isGranted;

    setState(() {
      _isAlertWindowGranted = alertStatus;
      _isNotificationGranted = notifStatus;
      _isExactAlarmGranted = exactStatus;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _vibration = prefs.getBool('vibration') ?? true;
      _volume = prefs.getDouble('volume') ?? 0.8;

      // Déli harangozás betöltése
      _noonBell = prefs.getBool('noon_bell') ?? false;
      _noonDurationSeconds = prefs.getInt('noon_duration') ?? 60; // Hossza betöltése

      if (_noonBell && Alarm.getAlarm(804) == null) {
        _toggleNoonBell(true);
      }

      if (prefs.getBool('jun4') == null) {
        _jun4 = true;
        _toggleJun4(true, skipConfirmation: true);
      } else {
        _jun4 = prefs.getBool('jun4')!;
        if (_jun4 && Alarm.getAlarm(604) == null) {
          _toggleJun4(true, skipConfirmation: true);
        }
      }
    });
  }

  Future<bool?> _showDisableConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2328),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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

  Future<void> _manageReminders(bool isJun4Off) async {
    if (isJun4Off) {
      final now = DateTime.now();

      DateTime targetUtc = DateTime.utc(now.year, 6, 4, 8, 0);
      if (targetUtc.isBefore(now.toUtc())) targetUtc = DateTime.utc(now.year + 1, 6, 4, 8, 0);

      final oneWeekBefore = targetUtc.subtract(const Duration(days: 7)).toLocal();
      final oneDayBefore = targetUtc.subtract(const Duration(days: 1)).toLocal();

      if (oneWeekBefore.isAfter(now)) {
        await Alarm.set(alarmSettings: AlarmSettings(
          id: 704,
          dateTime: oneWeekBefore,
          assetAudioPath: 'assets/harangozas2.mp3',
          volume: 0.0,
          notificationTitle: "Hé, ki van kapcsolva a harangozás!",
          notificationBody: "Már csak egy hét június 4-ig. Ne felejtsd el visszakapcsolni!",
        ));
      }

      if (oneDayBefore.isAfter(now)) {
        await Alarm.set(alarmSettings: AlarmSettings(
          id: 104,
          dateTime: oneDayBefore,
          assetAudioPath: 'assets/harangozas2.mp3',
          volume: 0.0,
          notificationTitle: "Holnap harangozunk!",
          notificationBody: "A harangozás gombod még mindig ki van kapcsolva. Állítsd vissza most!",
        ));
      }
    } else {
      await Alarm.stop(704);
      await Alarm.stop(104);
    }
  }

  Future<void> _toggleJun4(bool value, {bool skipConfirmation = false}) async {
    if (!value && !skipConfirmation) {
      final confirm = await _showDisableConfirmation();
      if (confirm != true) return;
    }

    setState(() => _jun4 = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('jun4', value);

    if (value) {
      final nowUtc = DateTime.now().toUtc();
      DateTime targetUtc = DateTime.utc(nowUtc.year, 6, 4, 14, 32);

      if (targetUtc.isBefore(nowUtc)) {
        targetUtc = DateTime.utc(nowUtc.year + 1, 6, 4, 14, 32);
      }

      final targetLocal = targetUtc.toLocal();

      await Alarm.set(alarmSettings: AlarmSettings(
        id: 604,
        dateTime: targetLocal,
        assetAudioPath: 'assets/harangozas2.mp3',
        loopAudio: true,
        vibrate: _vibration,
        volume: _volume,
        notificationTitle: 'ÖsszHarang',
        notificationBody: 'Trianoni Emlékharangozás',
        androidFullScreenIntent: true,
      ));
    } else {
      await Alarm.stop(604);
    }

    await _manageReminders(!value);
  }

  Future<void> _toggleNoonBell(bool value) async {
    setState(() => _noonBell = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('noon_bell', value);

    if (value) {
      final now = DateTime.now();
      DateTime target = DateTime(now.year, now.month, now.day, 12, 0);

      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }

      await Alarm.set(alarmSettings: AlarmSettings(
        id: 804,
        dateTime: target,
        assetAudioPath: 'assets/harangozas2.mp3',
        loopAudio: true, // Fontos: bekapcsolva, hogy hosszabb másodpercek esetén se akadjon meg
        vibrate: _vibration,
        volume: _volume,
        notificationTitle: 'ÖsszHarang',
        notificationBody: 'Déli harangszó',
        androidFullScreenIntent: true,
      ));
    } else {
      await Alarm.stop(804);
    }
  }

  // ÚJ: Déli harangozás idejének mentése
  Future<void> _saveNoonDuration(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('noon_duration', value);
  }

 Future<void> _saveVibration(bool value) async {
   setState(() => _vibration = value);
   final prefs = await SharedPreferences.getInstance();
   await prefs.setBool('vibration', value);
   // ITT KIVETTÜK az azonnali _toggleJun4 / _toggleNoonBell hívást,
   // így nem omlik össze a csúszkánál / kapcsolónál!
 }

 Future<void> _saveVolume(double value) async {
   setState(() => _volume = value);
   final prefs = await SharedPreferences.getInstance();
   await prefs.setDouble('volume', value);
   // ITT IS KIVETTÜK az újraütemezést, csak elmentjük a memóriába.
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBase,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/hatter.png',
              fit: BoxFit.cover,
            ),
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
                      _buildCard(
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
                              value: _jun4,
                              activeColor: Colors.cyanAccent.shade400,
                              onChanged: (val) => _toggleJun4(val),
                            ),
                          ],
                        ),
                      ),

                      // KÁRTYA: Déli harangozás + Csúszka
                      _buildCard(
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
                                  value: _noonBell,
                                  activeColor: Colors.cyanAccent.shade400,
                                  onChanged: _toggleNoonBell,
                                ),
                              ],
                            ),

                            // Csak akkor jelenik meg a csúszka, ha be van kapcsolva a déli harangozás
                            if (_noonBell) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 15.0),
                                child: Divider(color: Colors.white10, thickness: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Harangozás hossza", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                  Text("$_noonDurationSeconds mp", style: TextStyle(color: Colors.cyanAccent.shade400, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Slider(
                                value: _noonDurationSeconds.toDouble(),
                                min: 2, // A legkisebb érték mostantól 2
                                max: 300,
                                divisions: 298, // 300 - 2 = 298, így pontosan másodpercenként lehet léptetni
                                activeColor: Colors.cyanAccent.shade400,
                                inactiveColor: Colors.white10,
                                onChanged: (val) {
                                  setState(() => _noonDurationSeconds = val.toInt());
                                },
                                onChangeEnd: (val) {
                                  _saveNoonDuration(val.toInt());
                                },
                              ),
                            ]
                          ],
                        ),
                      ),

                      _buildCard(
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
                                  value: _vibration,
                                  activeColor: Colors.cyanAccent.shade400,
                                  onChanged: _saveVibration,
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Row(
                              children: [
                                const Icon(Icons.volume_down, color: Colors.white54, size: 20),
                                Expanded(
                                  child: Slider(
                                    value: _volume,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: Colors.cyanAccent.shade400,
                                    inactiveColor: Colors.white10,
                                    onChanged: _saveVolume,
                                  ),
                                ),
                                Icon(Icons.volume_up, color: Colors.cyanAccent.shade400, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),

                      _buildCard(
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

                      _buildCard(
                        icon: Icons.security,
                        iconColor: Colors.purpleAccent,
                        title: "Rendszerengedélyek",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Az alkalmazás pontos működéséhez és a teljes képernyős megjelenéshez az alábbi engedélyek szükségesek. Kérjük, ellenőrizze, hogy megadta-e őket.",
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 20),

                            _buildPermissionRow(
                              title: "Pontos időzítés",
                              description: "A harangozás percre pontos indításához.",
                              isGranted: _isExactAlarmGranted,
                              onRequest: () async {
                                await Permission.scheduleExactAlarm.request();
                                _checkPermissions();
                              },
                            ),
                            const Divider(color: Colors.white10, height: 20),

                            _buildPermissionRow(
                              title: "Értesítések küldése",
                              description: "A háttérben futó emlékeztetők megjelenítése.",
                              isGranted: _isNotificationGranted,
                              onRequest: () async {
                                await Permission.notification.request();
                                _checkPermissions();
                              },
                            ),
                            const Divider(color: Colors.white10, height: 20),

                            _buildPermissionRow(
                              title: "Megjelenítés legfelül",
                              description: "A teljes képernyős riasztás megjelenítéséhez lezárt képernyőnél is.",
                              isGranted: _isAlertWindowGranted,
                              onRequest: () async {
                                await Permission.systemAlertWindow.request();
                                _checkPermissions();
                              },
                            ),

                            const SizedBox(height: 15),

                            if (!_isAlertWindowGranted)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Text(
                                  "Ha a gomb nem működik:\n"
                                      "Samsung: Beállítások -> Alkalmazások -> Különleges alkalmazáshozzáférés -> Megjelenés legfelül\n"
                                      "Xiaomi: Beállítások -> Alkalmazások -> Engedélykezelés -> Egyéb engedélyek -> 'Megjelenítés felugró ablakként'",
                                  style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                                ),
                              ),
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

  Widget _buildPermissionRow({
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        isGranted
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
              SizedBox(width: 4),
              Text("Rendben", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        )
            : OutlinedButton(
          onPressed: onRequest,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orangeAccent),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text("Beállítás", style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildCard({required IconData icon, required Color iconColor, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}