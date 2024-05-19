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
      loopAudio: true,
      vibrate: false,
      volume: null,
      assetAudioPath: 'assets/harang3.mp3',
      notificationTitle: 'Trianoni évforduló',
      notificationBody: 'Trianoni évforduló',
    );

    // Ébresztő mentése
    bool success = await Alarm.set(alarmSettings: alarm);
    return success;
  }
}
