import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeProvider extends ChangeNotifier {
  // --- VISSZASZÁMLÁLÓ VÁLTOZÓK ---
  Timer? _clockTimer;
  Duration timeUntilTrianon = Duration.zero;

  // --- HARANGOZÁS (RINGING) VÁLTOZÓK ---
  StreamSubscription<AlarmSettings>? _subscription;
  bool isRinging = false;
  bool isPaused = false;
  int ringingSecondsRemaining = 0;
  int totalRingingSeconds = 0;
  int currentAlarmId = -1;
  Timer? _ringingTimer;

  bool isNoonBellActive = false;

  HomeProvider() {
    _startClockTimer();
    loadSettings();
    _listenToAlarms();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _ringingTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  // --- INICIALIZÁLÁS ÉS BETÖLTÉS ---

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isNoonBellActive = prefs.getBool('noon_bell') ?? false;
    notifyListeners();
  }

  void _listenToAlarms() {
    _subscription ??= Alarm.ringStream.stream.listen((alarmSettings) {
      if (isRinging) return;
      startRingingState(alarmSettings.id);
    });
  }

  // --- VISSZASZÁMLÁLÓ LOGIKA ---

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final nowUtc = DateTime.now().toUtc();

      // Magyarországon nyáron (jún 4) a 16:32 pontosan UTC 14:32-nek felel meg.
      DateTime targetUtc = DateTime.utc(nowUtc.year, 6, 4, 14, 32);

      if (nowUtc.isAfter(targetUtc)) {
        targetUtc = DateTime.utc(nowUtc.year + 1, 6, 4, 14, 32);
      }

      timeUntilTrianon = targetUtc.difference(nowUtc);
      notifyListeners();
    });
  }

  // --- HARANGOZÁS VEZÉRLŐ LOGIKA ---

  Future<void> startRingingState(int id) async {
    currentAlarmId = id;

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

    isRinging = true;
    isPaused = false;
    totalRingingSeconds = calculatedSeconds;
    ringingSecondsRemaining = calculatedSeconds;
    notifyListeners();

    _ringingTimer?.cancel();
    _ringingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (ringingSecondsRemaining > 0) {
        ringingSecondsRemaining--;
        notifyListeners();
      } else {
        stopRinging();
      }
    });
  }

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

  Future<void> togglePause() async {
    if (isPaused) {
      final prefs = await SharedPreferences.getInstance();
      final bool vibrate = prefs.getBool('vibration') ?? true;
      final double volume = prefs.getDouble('volume') ?? 0.8;

      final dummyAlarm = AlarmSettings(
        id: currentAlarmId,
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
      isPaused = false;
    } else {
      await Alarm.stop(currentAlarmId);
      isPaused = true;
    }
    notifyListeners();
  }

  Future<void> stopRinging() async {
    _ringingTimer?.cancel();

    // 1. Leállítjuk az éppen futó csörgést
    await Alarm.stop(currentAlarmId);

    // 2. MIUTÁN LEÁLLT, most már biztonságosan beállíthatjuk a következőt!
    if (currentAlarmId == 804) {
      await _scheduleNextNoonBell();
    } else if (currentAlarmId == 604) {
      await _scheduleNextJun4Bell();
    }

    isRinging = false;
    isPaused = false;
    notifyListeners();
  }

  // --- TESZT GOMB LOGIKA ---

  Future<void> startImmediateTest() async {
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

  Future<void> _scheduleNextJun4Bell() async {
    final prefs = await SharedPreferences.getInstance();
    final bool vibrate = prefs.getBool('vibration') ?? true;
    final double volume = prefs.getDouble('volume') ?? 0.8;

    final nowUtc = DateTime.now().toUtc();
    // Direkt a következő évre ütemezzük
    DateTime targetUtc = DateTime.utc(nowUtc.year + 1, 6, 4, 14, 32);
    final targetLocal = targetUtc.toLocal();

    await Alarm.set(alarmSettings: AlarmSettings(
      id: 604,
      dateTime: targetLocal,
      assetAudioPath: 'assets/harangozas2.mp3',
      loopAudio: true,
      vibrate: vibrate,
      volume: volume,
      notificationTitle: 'ÖsszHarang',
      notificationBody: 'Trianoni Emlékharangozás',
      androidFullScreenIntent: true,
    ));
  }
}