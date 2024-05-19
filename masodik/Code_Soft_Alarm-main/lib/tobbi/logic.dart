import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Logic {
  static Future<bool> createAndSaveAlarm() async {
    // Initialize time zones
    tz.initializeTimeZones();

    // Define the location for Budapest
    final String location = 'Europe/Budapest';
    final tz.Location budapest = tz.getLocation(location);

    // Get the current time in the Budapest time zone
    final tz.TZDateTime now = tz.TZDateTime.now(budapest);

    // Set the alarm time to June 4th, 16:32 in the Budapest time zone
    tz.TZDateTime juneFourth = tz.TZDateTime(budapest, now.year, 6, 4, 16, 32);

    // If the alarm time for this year has already passed, set it for next year
    if (juneFourth.isBefore(now)) {
      juneFourth = tz.TZDateTime(budapest, now.year + 1, 6, 4, 16, 32);
    }

    // Create the alarm settings
    AlarmSettings alarm = AlarmSettings(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      dateTime: juneFourth,
      loopAudio: true,
      vibrate: false,
      volume: 1.0,
      assetAudioPath: 'assets/harang.mp3',
      notificationTitle: 'Trianoni évforduló',
      notificationBody: 'Emlékezzünk a trianoni évfordulóra',
    );

    // Set the alarm
    bool success = await Alarm.set(alarmSettings: alarm);
    return success;
  }
}
