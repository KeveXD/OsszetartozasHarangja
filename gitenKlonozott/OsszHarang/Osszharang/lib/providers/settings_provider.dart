import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsProvider extends ChangeNotifier {
  // --- BEÁLLÍTÁS VÁLTOZÓK ---
  bool isJun4Active = true;
  bool isNoonBellActive = false;
  int noonDurationSeconds = 60;
  bool vibration = true;
  double volume = 0.8;

  // --- ENGEDÉLY ÁLLAPOTOK ---
  bool isAlertWindowGranted = false;
  bool isNotificationGranted = false;
  bool isExactAlarmGranted = false;

  SettingsProvider() {
    loadSettings();
    checkPermissions();
  }

  // Engedélyek lekérdezése
  Future<void> checkPermissions() async {
    isAlertWindowGranted = await Permission.systemAlertWindow.isGranted;
    isNotificationGranted = await Permission.notification.isGranted;
    isExactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;

    notifyListeners(); // Szólunk a felületnek, hogy frissültek az adatok
  }

  // Beállítások betöltése a memóriából
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    vibration = prefs.getBool('vibration') ?? true;
    volume = prefs.getDouble('volume') ?? 0.8;
    isNoonBellActive = prefs.getBool('noon_bell') ?? false;
    noonDurationSeconds = prefs.getInt('noon_duration') ?? 60;

    if (isNoonBellActive && Alarm.getAlarm(804) == null) {
      toggleNoonBell(true);
    }

    if (prefs.getBool('jun4') == null) {
      isJun4Active = true;
      toggleJun4(true);
    } else {
      isJun4Active = prefs.getBool('jun4')!;
      if (isJun4Active && Alarm.getAlarm(604) == null) {
        toggleJun4(true);
      }
    }

    notifyListeners();
  }

  // Trianoni harangozás kapcsolója
  Future<void> toggleJun4(bool value) async {
    isJun4Active = value;
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
        vibrate: vibration,
        volume: volume,
        notificationTitle: 'ÖsszHarang',
        notificationBody: 'Trianoni Emlékharangozás',
        androidFullScreenIntent: true,
      ));
    } else {
      await Alarm.stop(604);
    }

    await _manageReminders(!value);
    notifyListeners();
  }

  // Déli harangozás kapcsolója
  Future<void> toggleNoonBell(bool value) async {
    isNoonBellActive = value;
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
        loopAudio: true,
        vibrate: vibration,
        volume: volume,
        notificationTitle: 'ÖsszHarang',
        notificationBody: 'Déli harangszó',
        androidFullScreenIntent: true,
      ));
    } else {
      await Alarm.stop(804);
    }
    notifyListeners();
  }

  // Déli harangozás hossza
  Future<void> saveNoonDuration(int value) async {
    noonDurationSeconds = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('noon_duration', value);
    notifyListeners();
  }

  // Rezgés mentése
  Future<void> saveVibration(bool value) async {
    vibration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration', value);

    // Riasztások frissítése az új beállítással
    if (isJun4Active) toggleJun4(true);
    if (isNoonBellActive) toggleNoonBell(true);

    notifyListeners();
  }

  // Hangerő mentése
  Future<void> saveVolume(double value) async {
    volume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volume', value);

    // Riasztások frissítése az új beállítással
    if (isJun4Active) toggleJun4(true);
    if (isNoonBellActive) toggleNoonBell(true);

    notifyListeners();
  }

  // Emlékeztetők kezelése
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
}