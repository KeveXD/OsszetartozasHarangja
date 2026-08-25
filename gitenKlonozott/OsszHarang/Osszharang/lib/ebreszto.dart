import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Dátum formázásához

// Saját fájlok importja
import 'theme.dart';

class EbresztoPage extends StatefulWidget {
  const EbresztoPage({Key? key}) : super(key: key);

  @override
  State<EbresztoPage> createState() => _EbresztoPageState();
}

class _EbresztoPageState extends State<EbresztoPage> {
  // --- BEÁLLÍTÁS VÁLTOZÓK ---
  bool _isAlarmOn = false;
  bool _vibration = true;
  double _volume = 0.8;
  int _durationSeconds = 60; // Alapértelmezett harangozási idő (60 mp)

  // A kiválasztott dátum és időpont (alapértelmezett: holnap reggel 7:00)
  late DateTime _selectedDateTime;

  // Fix azonosító a saját ébresztőnek (hogy ne keveredjen a 604-es Trianonnal)
  final int _customAlarmId = 888;

  @override
  void initState() {
    super.initState();
    // Kezdőérték beállítása (ma, ha elmúlt, akkor holnap 07:00)
    final now = DateTime.now();
    _selectedDateTime = DateTime(now.year, now.month, now.day, 7, 0);
    if (_selectedDateTime.isBefore(now)) {
      _selectedDateTime = _selectedDateTime.add(const Duration(days: 1));
    }

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _vibration = prefs.getBool('custom_vibration') ?? true;
      _volume = prefs.getDouble('custom_volume') ?? 0.8;
      _durationSeconds = prefs.getInt('custom_duration') ?? 60;

      // Mentett dátum és idő betöltése (ha van)
      final savedIso = prefs.getString('custom_datetime');
      if (savedIso != null) {
        _selectedDateTime = DateTime.parse(savedIso);
        // Ha a mentett dátum már elmúlt, frissítjük a jövőbe
        if (_selectedDateTime.isBefore(DateTime.now())) {
          _selectedDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, _selectedDateTime.hour, _selectedDateTime.minute);
          if (_selectedDateTime.isBefore(DateTime.now())) {
            _selectedDateTime = _selectedDateTime.add(const Duration(days: 1));
          }
        }
      }

      // Szinkronizáció az Alarm motorral: Be van-e épp állítva a saját ébresztőnk a jövőbe?
      final currentAlarm = Alarm.getAlarm(_customAlarmId);
      _isAlarmOn = currentAlarm != null;
    });
  }

  // --- KOMPLEX IDŐPONT ÉS DÁTUM VÁLASZTÓ ---
  Future<void> _pickDateTime() async {
    // 1. Dátum kiválasztása
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(), // Nem lehet múltbeli napot választani
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.cyanAccent.shade400,
              onPrimary: Colors.black,
              surface: const Color(0xFF1E2328),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return; // Megszakította a választást

    // 2. Idő kiválasztása
    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedDateTime.hour, minute: _selectedDateTime.minute),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.cyanAccent.shade400,
              onPrimary: Colors.black,
              surface: const Color(0xFF1E2328),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return; // Megszakította a választást

    // 3. Összefűzzük a kettőt
    DateTime newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Biztonsági ellenőrzés: Ne állíthasson be múltbeli időpontot a mai napra
    if (newDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A múltba nem állíthatsz be ébresztőt!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _selectedDateTime = newDateTime;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_datetime', newDateTime.toIso8601String());

    // Ha be volt kapcsolva, újra beállítjuk az új időpontra
    if (_isAlarmOn) {
      _toggleAlarm(true);
    }
  }

  // Ébresztő be- és kikapcsolása
  Future<void> _toggleAlarm(bool value) async {
    setState(() => _isAlarmOn = value);

    if (value) {
      // Csak biztonságból megnézzük, hogy az időpont jó-e
      if (_selectedDateTime.isBefore(DateTime.now())) {
        setState(() {
          _selectedDateTime = _selectedDateTime.add(const Duration(days: 1));
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_datetime', _selectedDateTime.toIso8601String());
      }

      final alarmSettings = AlarmSettings(
        id: _customAlarmId,
        dateTime: _selectedDateTime,
        assetAudioPath: 'assets/harangozas2.mp3',
        loopAudio: true,
        vibrate: _vibration,
        volume: _volume,
        notificationTitle: 'ÖsszHarang Ébresztő',
        notificationBody: 'Itt az idő!',
        androidFullScreenIntent: true,
      );

      await Alarm.set(alarmSettings: alarmSettings);
    } else {
      await Alarm.stop(_customAlarmId);
    }
  }

  Future<void> _saveVibration(bool value) async {
    setState(() => _vibration = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('custom_vibration', value);

    if (_isAlarmOn) _toggleAlarm(true);
  }

  Future<void> _saveVolume(double value) async {
    setState(() => _volume = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('custom_volume', value);

    if (_isAlarmOn) _toggleAlarm(true);
  }

  Future<void> _saveDuration(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_duration', value);
  }

  // --- UI ÉPÍTÉS ---

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('yyyy. MM. dd.').format(_selectedDateTime);
    final String formattedTime = DateFormat('HH:mm').format(_selectedDateTime);

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
                // --- FEJLÉC (< Vissza) ---
                Padding(
                  padding: const EdgeInsets.only(top: 15.0, left: 15.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Vissza",
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- NAGY CÍM ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
                  child: Text(
                    "Ébresztő",
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),

                // --- KÁRTYÁK (Görgethető lista) ---
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    physics: const BouncingScrollPhysics(),
                    children: [

                      // 1. KÁRTYA: Egyedi harangozás beállítása
                      _buildCard(
                        icon: Icons.alarm,
                        iconColor: Colors.orangeAccent,
                        title: "Saját harangozás",
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Dátum és Időpont", style: TextStyle(color: Colors.white54, fontSize: 13)),
                                    const SizedBox(height: 5),
                                    InkWell(
                                      onTap: _pickDateTime,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                  color: _isAlarmOn ? Colors.cyanAccent.shade400 : Colors.white,
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 2.0
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                  color: _isAlarmOn ? Colors.cyanAccent.withOpacity(0.7) : Colors.white70,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                CupertinoSwitch(
                                  value: _isAlarmOn,
                                  activeColor: Colors.cyanAccent.shade400,
                                  onChanged: _toggleAlarm,
                                ),
                              ],
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 15.0),
                              child: Divider(color: Colors.white10, thickness: 1),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Harangozás hossza", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                Text("$_durationSeconds mp", style: TextStyle(color: Colors.cyanAccent.shade400, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Slider(
                              value: _durationSeconds.toDouble(),
                              min: 10,
                              max: 300,
                              divisions: 29,
                              activeColor: Colors.cyanAccent.shade400,
                              inactiveColor: Colors.white10,
                              onChanged: (val) {
                                setState(() => _durationSeconds = val.toInt());
                              },
                              onChangeEnd: (val) {
                                _saveDuration(val.toInt());
                              },
                            ),
                          ],
                        ),
                      ),

                      // 2. KÁRTYA: Hangbeállítások
                      _buildCard(
                        icon: Icons.volume_up,
                        iconColor: Colors.greenAccent,
                        title: "Hangbeállítások",
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text("Rezgés harangozáskor", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                  ],
                                ),
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
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}