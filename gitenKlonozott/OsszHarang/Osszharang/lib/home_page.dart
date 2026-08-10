import 'dart:async';
import 'dart:ui';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

// Saját fájlok importja
import 'beallitasok.dart';
import 'ebreszto.dart';
import 'theme.dart';
import 'strings.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- VISSZASZÁMLÁLÓ VÁLTOZÓK ---
  Timer? _clockTimer;
  Duration _timeUntilTrianon = Duration.zero;

  // --- HARANGOZÁS (RINGING) VÁLTOZÓK ---
  static StreamSubscription<AlarmSettings>? subscription;
  bool _isRinging = false;
  bool _isPaused = false;
  int _ringingSecondsRemaining = 0;
  int _totalRingingSeconds = 0;
  int _currentAlarmId = -1;
  Timer? _ringingTimer;

  // ÚJ VÁLTOZÓ ÉS FÜGGVÉNY:
  bool _isNoonBellActive = false;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isNoonBellActive = prefs.getBool('noon_bell') ?? false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('hu_HU', null);

    _startClockTimer();
    _loadSettings();

    // Rácsatlakozunk az Alarm csomag eseményeire
    subscription ??= Alarm.ringStream.stream.listen((alarmSettings) {
      if (_isRinging) return;
      _startRingingState(alarmSettings.id);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _ringingTimer?.cancel();
    subscription?.cancel();
    super.dispose();
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final nowUtc = DateTime.now().toUtc();

      // Magyarországon nyáron (jún 4) a 16:32 pontosan UTC 14:32-nek felel meg.
      DateTime targetUtc = DateTime.utc(nowUtc.year, 6, 4, 14, 32);

      if (nowUtc.isAfter(targetUtc)) {
        targetUtc = DateTime.utc(nowUtc.year + 1, 6, 4, 14, 32);
      }

      setState(() {
        // A különbséget a két fix UTC időpont között számoljuk
        _timeUntilTrianon = targetUtc.difference(nowUtc);
      });
    });
  }

  // --- HARANGOZÁS VEZÉRLŐ LOGIKA ---

  Future<void> _startRingingState(int id) async {
    _currentAlarmId = id;

    // Ha a déli harangozás szólalt meg (ID: 804), azonnal ütemezzük a holnapit
    if (id == 804) {
      _scheduleNextNoonBell();
    }

    // Kiszámoljuk az összes másodpercet az ID alapján
    int calculatedSeconds = 0;

    if (id == 999) {
      // Teszt
      calculatedSeconds = 10;
    } else if (id == 888) {
      // Saját ébresztő: Kiolvassuk a beállított hosszt
      final prefs = await SharedPreferences.getInstance();
      calculatedSeconds = prefs.getInt('custom_duration') ?? 60;
    } else if (id == 804) {
      // Déli harangozás: Kiolvassuk a beállított hosszt
      final prefs = await SharedPreferences.getInstance();
      calculatedSeconds = prefs.getInt('noon_duration') ?? 60;
    } else {
      // Június 4. (Trianon)
      calculatedSeconds = DateTime.now().year - 1920;
    }

    if (!mounted) return;

    setState(() {
      _isRinging = true;
      _isPaused = false;
      _totalRingingSeconds = calculatedSeconds;
      _ringingSecondsRemaining = calculatedSeconds;
    });

    _ringingTimer?.cancel();
    _ringingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_ringingSecondsRemaining > 0) {
          _ringingSecondsRemaining--;
        } else {
          _stopRinging();
        }
      });
    });
  }

  // ÚJ SEGÉDFÜGGVÉNY: Újraütemezi a másnapi déli harangozást
  Future<void> _scheduleNextNoonBell() async {
    final prefs = await SharedPreferences.getInstance();
    final bool vibrate = prefs.getBool('vibration') ?? true;
    final double volume = prefs.getDouble('volume') ?? 0.8;

    // Holnap 12:00
    final tomorrowNoon = DateTime.now().add(const Duration(days: 1));
    final target = DateTime(tomorrowNoon.year, tomorrowNoon.month, tomorrowNoon.day, 12, 0);

    await Alarm.set(alarmSettings: AlarmSettings(
      id: 804,
      dateTime: target,
      assetAudioPath: 'assets/harangozas2.mp3',
      loopAudio: true,
      vibrate: vibrate,
      volume: volume,
      notificationTitle: 'ÖsszHarang',
      notificationBody: 'Déli harangszó',
      androidFullScreenIntent: true,
    ));
  }

  Future<void> _togglePause() async {
    if (_isPaused) {
      final prefs = await SharedPreferences.getInstance();
      final bool vibrate = prefs.getBool('vibration') ?? true;
      final double volume = prefs.getDouble('volume') ?? 0.8;

      final dummyAlarm = AlarmSettings(
        id: _currentAlarmId,
        dateTime: DateTime.now(),
        assetAudioPath: 'assets/harangozas2.mp3',
        loopAudio: true,
        vibrate: vibrate,
        volume: volume,
        notificationTitle: 'ÖsszHarang',
        notificationBody: 'Harangozás folyamatban...',
        androidFullScreenIntent: false,
      );

      await Alarm.set(alarmSettings: dummyAlarm);
      setState(() => _isPaused = false);
    } else {
      await Alarm.stop(_currentAlarmId);
      setState(() => _isPaused = true);
    }
  }

  Future<void> _stopRinging() async {
    _ringingTimer?.cancel();
    await Alarm.stop(_currentAlarmId);
    setState(() {
      _isRinging = false;
      _isPaused = false;
    });
  }

  // --- TESZT GOMB LOGIKA ---
  Future<void> _startImmediateTest() async {
    final prefs = await SharedPreferences.getInstance();
    final bool vibrate = prefs.getBool('vibration') ?? true;
    final double volume = prefs.getDouble('volume') ?? 0.8;

    final testAlarm = AlarmSettings(
      id: 999,
      dateTime: DateTime.now(),
      assetAudioPath: 'assets/harangozas2.mp3',
      loopAudio: true,
      vibrate: vibrate,
      volume: volume,
      notificationTitle: 'Teszt Harangozás',
      notificationBody: 'Teszt folyamatban...',
    );

    await Alarm.stop(999);
    await Alarm.set(alarmSettings: testAlarm);
  }

  // --- WEBOLDAL MEGNYITÁSA ---
  Future<void> _launchUrl() async {
    final Uri url = Uri.parse('https://osszharang.com');
    if (!await launcher.launchUrl(url, mode: launcher.LaunchMode.externalApplication)) {
      debugPrint('Hiba a weboldal megnyitásakor');
    }
  }

  // --- INFORMÁCIÓS ABLAK (JAVÍTOTT ÜVEGHATÁSÚ DIALOG) ---
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.white24, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_edu, color: Colors.orangeAccent, size: 26),
                      const SizedBox(width: 10),
                      const Text(
                        "Miért szól a harang?",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Text(
                          AppStrings.trianonDescription,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                          "BEZÁRÁS",
                          style: TextStyle(color: Colors.cyanAccent.shade400, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- UI ÉPÍTÉS ---

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
            child: Stack(
              children: [
              SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 4),

                  if (_isRinging && _isPaused)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        "ELNÉMÍTVA",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            fontSize: 12
                        ),
                      ),
                    ),

                  // Dinamikus méret (harangozáskor: 180, alapból: 70)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isRinging ? 180 : 70,
                    child: _isRinging
                        ? Image.asset('assets/harangozas.gif', fit: BoxFit.contain)
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset('assets/harangborito.png', fit: BoxFit.contain),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "ÖSSZHARANG",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      letterSpacing: 8.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "TRIANONI EMLÉKEZÉS • JÚNIUS 4.",
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 12,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "16:32 KözépEU idő",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: _isRinging ? _buildRingingUI() : _buildCountdownUI(),
                  ),

                  const SizedBox(height: 30),

                  if (!_isRinging)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildOutlinedButton(
                          icon: Icons.play_arrow_outlined,
                          label: "Teszt 10mp",
                          onTap: _startImmediateTest,
                        ),
                        const SizedBox(width: 15),
                        _buildOutlinedButton(
                          icon: Icons.settings_outlined,
                          label: "Beállítások",
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const BeallitasokPage())
                            ).then((_) => _loadSettings()); // Itt van a változás!
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 30),

                  if (!_isRinging) // Gombok elrejtése csörgéskor a letisztultabb UI érdekében
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTextButton(
                            icon: Icons.alarm,
                            label: "Ébresztő",
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const EbresztoPage()));
                            }
                        ),
                        const SizedBox(width: 8),
                        _buildTextButton(
                            icon: Icons.info_outline,
                            label: "Információ",
                            onTap: () => _showInfoDialog(context)
                        ),
                        const SizedBox(width: 8),
                        _buildTextButton(
                            icon: Icons.open_in_new,
                            label: "Weboldal",
                            onTap: _launchUrl
                        ),
                      ],
                    ),

                  const Spacer(flex: 2),

                  const Text(
                    "1920. JÚNIUS 4. — TRIANONI BÉKEDIKTÁTUM",
                    style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 10),
                  Image.asset('assets/trianon.gif', height: 110),

                  const SizedBox(height: 30),
                ],
              ),
              ),

                // ÚJ KÓD: DÉLI HARANGOZÁS JELZŐ IKON
                if (_isNoonBellActive && !_isRinging)
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.wb_sunny_outlined, color: Colors.amberAccent, size: 14),
                          SizedBox(width: 5),
                          Text("Déli harang", style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI RÉSZEGYSÉGEK ---

  Widget _buildCountdownUI() {
    int days = _timeUntilTrianon.inDays;
    int hours = _timeUntilTrianon.inHours.remainder(24);
    int minutes = _timeUntilTrianon.inMinutes.remainder(60);
    int seconds = _timeUntilTrianon.inSeconds.remainder(60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeBox(days.toString(), "NAP"),
        _buildColon(),
        _buildTimeBox(hours.toString().padLeft(2, '0'), "ÓRA"),
        _buildColon(),
        _buildTimeBox(minutes.toString().padLeft(2, '0'), "PERC"),
        _buildColon(),
        _buildTimeBox(seconds.toString().padLeft(2, '0'), "MP"),
      ],
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Container(
      width: 70,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildColon() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 15),
      child: Text(":", style: TextStyle(fontSize: 24, color: Colors.white54, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRingingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: ElevatedButton.icon(
            onPressed: _togglePause,
            icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.volume_off,
                color: Colors.white
            ),
            label: Text(
                _isPaused ? "FOLYTATÁS ($_ringingSecondsRemaining mp)" : "Elnémítás",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2
                )
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPaused ? const Color(0xFF1DB954) : const Color(0xFFFF5722),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
          ),
        ),

        // KIZÁRÓLAG AZ ÉBRESZTŐNÉL (888-as ID) LÁTSZÓDIK A LEÁLLÍTÓ GOMB
        if (_currentAlarmId == 888) ...[
          const SizedBox(height: 15),
          SizedBox(
            width: 260,
            child: ElevatedButton.icon(
              onPressed: _stopRinging,
              icon: const Icon(Icons.stop_circle, color: Colors.white),
              label: const Text(
                  "ÉBRESZTŐ LEÁLLÍTÁSA",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2
                  )
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
            ),
          ),
        ],

        const SizedBox(height: 15),
        Text(
          "$_ringingSecondsRemaining / $_totalRingingSeconds mp",
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: 1.5
          ),
        ),
      ],
    );
  }

  Widget _buildOutlinedButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white70, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white54, width: 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildTextButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}