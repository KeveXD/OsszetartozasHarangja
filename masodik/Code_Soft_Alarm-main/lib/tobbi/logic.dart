import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Logic {
  static Future<bool> createAndSaveAlarm() async {
    // Időzóna adatbázis inicializálása
    tz.initializeTimeZones();

<<<<<<< Updated upstream
    // Aktuális időzóna meghatározása
    final String? location = tz.local.name;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
=======
    // Define the location for Budapest
    const String location = 'Europe/Budapest';
    final tz.Location budapest = tz.getLocation(location);
>>>>>>> Stashed changes

    // Június 4. 16:35 kiválasztása
    tz.TZDateTime juneFourth = tz.TZDateTime(tz.local, now.year, 6, 4, 16, 35);

<<<<<<< Updated upstream
    // Ébresztő létrehozása a kiválasztott idővel
    AlarmSettings alarm = AlarmSettings(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      dateTime: juneFourth,
      loopAudio: true, // Példaként hagytam a loopAudio értékét true-nak, de ez változtatható
      vibrate: false, // Példaként hagytam a vibrate értékét false-nak, de ez változtatható
      volume: null, // Példaként hagytam a volume értékét null-nak, de ez változtatható
      assetAudioPath: 'assets/harang.mp3', // Példaként hagytam a hang útvonalát, de ez változtatható
      notificationTitle: 'Trianoni évforduló',
      notificationBody: 'Your alarm is ringing', // Itt az ébresztés szövege változtatható
=======
//todo
    tz.TZDateTime juneFourth = tz.TZDateTime(budapest, now.year, 5, 20, 16, 01);

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
      assetAudioPath: 'assets/harang3.mp3',
      notificationTitle: 'Összharang',
      notificationBody: 'Trianoni Évforduló',
>>>>>>> Stashed changes
    );


    bool success = await Alarm.set(alarmSettings: alarm);
    return success;
  }
}
