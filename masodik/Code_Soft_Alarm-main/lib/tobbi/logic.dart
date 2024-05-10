import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Logic {
  static Future<bool> createAndSaveAlarm() async {
    // Időzóna adatbázis inicializálása
    tz.initializeTimeZones();

    // Aktuális időzóna meghatározása
    final String? location = tz.local.name;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Június 4. 16:35 kiválasztása
    tz.TZDateTime juneFourth = tz.TZDateTime(tz.local, now.year, 6, 4, 16, 32);

    // Ébresztő létrehozása a kiválasztott idővel
    AlarmSettings alarm = AlarmSettings(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      dateTime: juneFourth,
      loopAudio: true, // Példaként hagytam a loopAudio értékét true-nak, de ez változtatható
      vibrate: false, // Példaként hagytam a vibrate értékét false-nak, de ez változtatható
      volume: null, // Példaként hagytam a volume értékét null-nak, de ez változtatható
      assetAudioPath: 'assets/harang.mp3', // Példaként hagytam a hang útvonalát, de ez változtatható
      notificationTitle: 'Trianoni évforduló',
      notificationBody: 'Trianoni évforduló', // Itt az ébresztés szövege változtatható
    );

    // Ébresztő mentése
    bool success = await Alarm.set(alarmSettings: alarm);
    return success;
  }
}
