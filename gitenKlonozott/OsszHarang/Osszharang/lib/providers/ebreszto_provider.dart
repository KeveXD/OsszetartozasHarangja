import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';

class EbresztoProvider extends ChangeNotifier {
  bool isAlarmOn = false;
  bool vibration = true;
  double volume = 0.8;
  int durationSeconds = 60;

  late DateTime selectedDateTime;
  final int customAlarmId = 888;

  EbresztoProvider() {
    // Alapértelmezett idő beállítása (holnap reggel 7:00)
    final now = DateTime.now();
    selectedDateTime = DateTime(now.year, now.month, now.day, 7, 0);
    if (selectedDateTime.isBefore(now)) {
      selectedDateTime = selectedDateTime.add(const Duration(days: 1));
    }
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    vibration = prefs.getBool('custom_vibration') ?? true;
    volume = prefs.getDouble('custom_volume') ?? 0.8;
    durationSeconds = prefs.getInt('custom_duration') ?? 60;

    final savedIso = prefs.getString('custom_datetime');
    if (savedIso != null) {
      selectedDateTime = DateTime.parse(savedIso);
      if (selectedDateTime.isBefore(DateTime.now())) {
        selectedDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, selectedDateTime.hour, selectedDateTime.minute);
        if (selectedDateTime.isBefore(DateTime.now())) {
          selectedDateTime = selectedDateTime.add(const Duration(days: 1));
        }
      }
    }

    final currentAlarm = Alarm.getAlarm(customAlarmId);
    isAlarmOn = currentAlarm != null;

    notifyListeners();
  }

  Future<void> toggleAlarm(bool value) async {
    isAlarmOn = value;

    if (value) {
      if (selectedDateTime.isBefore(DateTime.now())) {
        selectedDateTime = selectedDateTime.add(const Duration(days: 1));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_datetime', selectedDateTime.toIso8601String());
      }

      final alarmSettings = AlarmSettings(
        id: customAlarmId,
        dateTime: selectedDateTime,
        assetAudioPath: 'assets/harangozas2.mp3',
        loopAudio: true,
        vibrate: vibration,
        volume: volume,
        notificationTitle: 'ÖsszHarang Ébresztő',
        notificationBody: 'Itt az idő!',
        androidFullScreenIntent: true,
      );

      await Alarm.set(alarmSettings: alarmSettings);
    } else {
      await Alarm.stop(customAlarmId);
    }
    notifyListeners();
  }

  Future<void> updateDateTime(DateTime newDateTime) async {
    selectedDateTime = newDateTime;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_datetime', newDateTime.toIso8601String());

    if (isAlarmOn) {
      toggleAlarm(true);
    }
    notifyListeners();
  }

  Future<void> saveVibration(bool value) async {
    vibration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('custom_vibration', value);
    if (isAlarmOn) toggleAlarm(true);
    notifyListeners();
  }

  Future<void> saveVolume(double value) async {
    volume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('custom_volume', value);
    if (isAlarmOn) toggleAlarm(true);
    notifyListeners();
  }

  Future<void> saveDuration(int value) async {
    durationSeconds = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_duration', value);
    notifyListeners();
  }
}