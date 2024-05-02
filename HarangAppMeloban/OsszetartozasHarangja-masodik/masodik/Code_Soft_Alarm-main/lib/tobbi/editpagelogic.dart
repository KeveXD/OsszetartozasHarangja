import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:intl/intl.dart';

class EditPageLogic {
  static void createAndSaveAlarm() {
    // Június 4. 16:34 kiválasztása
    DateTime juneFourth = DateTime(DateTime.now().year, 6, 4, 16, 34);

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
    );

    // Ébresztő mentése
    Alarm.set(alarmSettings: alarm).then((success) {
      if (success) {
        // Sikeres mentés esetén visszajelzés
        print('Ébresztő sikeresen létrehozva és mentve!');
      } else {
        // Sikertelen mentés esetén visszajelzés
        print('Hiba történt az ébresztő létrehozása és mentése közben!');
      }
    });
  }

  static DateTime convertStringToDateTime(String timeString) {
    DateFormat format = DateFormat('HH:mm');
    DateTime dateTime = format.parse(timeString);

    DateTime today = DateTime.now();
    dateTime = DateTime(today.year, today.month, today.day, dateTime.hour, dateTime.minute);

    return dateTime;
  }
}
